class OrdinaryOrder < Order
  validates :user_address_id, presence: true

  enum state: { unpay: 0, payed: 1, shiped: 3, signed: 4, closed: 5, completed: 6 }

  scope :with_refunds, -> { joins(order_items: :order_item_refunds).uniq }
  scope :can_evaluate, -> { where(state: [OrdinaryOrder.states[:signed], OrdinaryOrder.states[:completed]]) }


  before_create :set_info_by_user_address, :set_ship_price
  after_commit :update_pay_amount_and_close_prepay, on: :update, if: -> {
    previous_changes.include?(:ship_price) &&
    previous_changes[:ship_price].first != previous_changes[:ship_price].last
  }

  aasm column: :state, enum: true, skip_validation_on_save: true, whiny_transitions: false do
    state :unpay
    state :payed, after_enter: [:after_payed]
    state :shiped,    after_enter: [:fill_shiped_at, :close_order_item_refund_before_shiping]
    state :signed,    after_enter: [:fill_signed_at, :active_privilege_card, :close_refunds_before_signed, :after_signed]
    state :completed, after_enter: [:fill_completed_at, :after_completed]
    state :closed,    after_enter: [:recover_product_stock, :after_close]

    event :pay, after_commit: :invoke_order_payed_processes do
      transitions from: :unpay, to: :payed
    end
    event :ship do
      transitions from: :payed, to: :shiped do
        guard do
          can_be_ship?
        end
      end
    end
    event :sign, after_commit: :call_order_complete_handler do
      transitions from: :shiped, to: :signed
      transitions from: :payed, to: :signed, guards: :single_official_agent?
    end
    event :close do
      transitions from: :unpay, to: :closed
    end
    event :complete do
      transitions from: :signed, to: :completed
    end
  end

  class << self
    def valid_items(cart_items, province)
      if province.present?
        province = ChinaCity.get(province)
        cart_items.inject([]){ |items, cart_item| valid_to_sales?(cart_item.product_inventory.product, province) ? items << cart_item : items  }
      else
        cart_items
      end
    end

    def valid_to_sales?(product, province)   # province = "北京市"
      if province.present? && product.transportation_way == 2 && product.carriage_template
        different_areas = product.carriage_template.different_areas
        different_areas.joins(:regions).where(regions: {name: province}).first.present? ? true : false
      else
        true
      end
    end

    # items1 是统一邮费, items2 是运费模板, user_address: 寄货地址
    def total_ship_price(items1, items2, user_address)
      return 0.0 if items1.blank? && items2.blank?
      begin
        province = ChinaCity.get(user_address.province)
      rescue
        return 0.0
      end
      max_traffic = max_traffic_expense(items1)
      carriage_template_group, items_count = uniq_carriage_template(items2)
      different_areas = find_all_different_areas(carriage_template_group, province)

      max_carriage_expense = (different_areas.sort_by{ |area| [-area.carriage, area.extend_carriage] }.try(:first) || 0)

      if max_traffic.to_f >= max_carriage_expense.try(:carriage).to_f && max_carriage_expense.try(:extend_carriage).to_f >= 0
        ship_price = max_traffic
        different_areas.each_with_index do |area, index|
          ship_price += carriage_way(area, items_count[index])
        end
      else
        ship_price = max_traffic + max_carriage_expense.carriage
        different_areas.each_with_index do |area, index|
          if area == max_carriage_expense
            balance = items_count[index] - max_carriage_expense.first_item
            ship_price += carriage_way(area, balance) if balance > 0
            next
          end
          ship_price += carriage_way(area, items_count[index])
        end
      end

      ship_price || 0.0
    end

    def carriage_way(different_area, count)
      extend_price = count.to_f / different_area.extend_item.to_f
      different_area.extend_carriage * ( extend_price < 1 ? 1 : extend_price.round )
    end

    def find_template_by_address(carriage_template, address)
      different_areas = carriage_template.different_areas
      different_areas.joins(:regions).where(regions: {name: address}).try(:first)
    end

    def find_all_different_areas(items, province)
      different_areas = []
      items.each do |item|
        different_areas.push(find_template_by_address(item.product_inventory.carriage_template, province))
      end
      different_areas.compact
    end

    def max_traffic_expense(items1)
      return 0 if items1.blank?
      items1.map { |item| item.product_inventory.product.traffic_expense }.max
    end

    def carriage_template_group_by(items2)
      items2.group_by{ |item| item.product_inventory.carriage_template_id }
    end

    def uniq_carriage_template(items2)
      uniq_items, items_count = [], []
      return [uniq_items, items_count] if items2.blank?
      carriage_template_group_by(items2).each do |carriage_template_id, items|
        items_count.push(items.sum{ |item| item.count })
        uniq_items.push(items.first)
      end
      [uniq_items, items_count]
    end

    def calculate_ship_price(cart_items, user_address)
      cart_items = meet_full_cut?(cart_items)

      items1 = cart_items.select{ |item| item.product_inventory.transportation_way == 1 }
      items2 = cart_items.select{ |item| item.product_inventory.transportation_way == 2 }

      total_ship_price(items1, items2, user_address)
    end

    # 运费满减
    def meet_full_cut?(cart_items)
      full_cut_items = cart_items.select{ |item| item.product_inventory.full_cut }
      cut_items = []

      full_cut_items.each do |item|
        if OrdinaryProduct::FullCut[item.product_inventory.full_cut_unit] == '件'
          cut_items.push(item) if item.count >= item.product_inventory.full_cut_number
        else
          cut_items.push(item) if (item.count * item.product_inventory.price) >= item.product_inventory.full_cut_number
        end
      end

      return cart_items - cut_items
    end
  end

  def ship_info
    "#{address} #{username}(收)"
  end

  def can_be_ship?
    if !self.seller.default_get_address.present?
      errors[:base] << "请设置默认退货地址"
      false
    else
      true
    end
  end

  def has_payed?
    OrdinaryOrder.states[self.state] >= 1 && OrdinaryOrder.states[self.state] != 5
  end

  def has_refund?
    order_items.joins(:order_item_refunds).exists?
  end

  def auto_sign_date
    @auto_sign_date ||= if paid_at >= Time.parse('2016-02-06') && paid_at <= Time.parse('2016-02-12')
                          shiped_at + 15.days
                        else
                          shiped_at + 9.days
                        end
  end

  private

  def update_pay_amount_and_close_prepay
    update_pay_amount
    OrderCharge.delay.check_and_close_prepay(order_charges: [order_charge])
  end

  def set_info_by_user_address
    self.address = "#{user_address}"
    self.mobile = user_address.mobile
    self.username = user_address.username
  end

  def set_ship_price
    self.ship_price = calculate_ship_price
  end

  def calculate_ship_price
    cart_items = OrdinaryOrder.meet_full_cut?(order_items)

    items1 = cart_items.select{ |item| item.product_inventory.transportation_way == 1 }
    items2 = cart_items.select{ |item| item.product_inventory.transportation_way == 2 }

    OrdinaryOrder.total_ship_price(items1, items2, user_address)
  end

  def fill_shiped_at
    update_column(:shiped_at, Time.now)
  end

  def fill_signed_at
    update_column(:signed_at, Time.now)
  end

  def active_privilege_card
    order_items.each(&:active_privilege_card)
  end

  def fill_completed_at
    update_column(:completed_at, Time.now)
  end

  def recover_product_stock
    order_items.each { |order_item| order_item.recover_product_stock }
  end

  def invoke_order_payed_processes
    # 在work 中判断订单是否是创客权订单
    OfficialAgentOrderJob.set(wait: 5.seconds).perform_later(self)
    OrderPayedJob.set(wait: 2.seconds).perform_later(self)
  end

  def call_order_complete_handler
    OrderDivideJob.set(wait: 5.seconds).perform_later(self)
  end

  def single_official_agent?
    order_items.size == 1 && official_agent?
  end

  def close_order_item_refund_before_shiping
    order_items.joins(:order_item_refunds).uniq.each do |item|
      refund = item.last_refund
      if refund.may_close? && refund.close!
        refund.refund_messages.create(
          user_type: '卖家',
          user_id: seller_id,
          message: '商家选择发货，退款申请关闭',
          action: '退款关闭'
        )
      end
    end
  end

  def close_refunds_before_signed
    order_items.joins(:order_item_refunds).uniq.each do |item|
      refund = item.last_refund
      if refund.may_close? && refund.close!
        refund.refund_messages.create(
          user_type: '买家',
          user_id: user_id,
          message: '买家确认收货，退款申请关闭',
          action: '退款关闭'
        )
      end
    end
  end

end
