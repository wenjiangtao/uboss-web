class OrderItem < ActiveRecord::Base

  belongs_to :user
  belongs_to :order
  belongs_to :product
  belongs_to :ordinary_product, foreign_key: :product_id
  belongs_to :service_product, foreign_key: :product_id
  belongs_to :product_inventory
  belongs_to :sharing_node
  has_many   :evaluations
  has_many   :sharing_incomes
  has_many   :verify_codes, -> { where(target_type: 'OrderItem') }, foreign_key: :target_id, autosave: true
  has_many   :order_item_refunds
  has_many   :refund_messages, through: :order_item_refunds
  # act as preferential_item
  has_many   :preferential_measures, as: :preferential_item, validate: false
  has_many   :preferentials_seller_bonuses, as: :preferential_item, class_name: 'Preferentials::SellerBonus', validate: false
  has_many   :preferentials_privileges, as: :preferential_item, class_name: 'Preferentials::Privilege', validate: false

  validates :user, :product_inventory, :amount, :present_price, :pay_amount, presence: true

  delegate :name, :traffic_expense, to: :product, prefix: true
  delegate :product_name, :price, :sku_attributes, :sku_attributes_str, to: :product_inventory
  delegate :privilege_card, to: :sharing_node, allow_nil: true
  delegate :type, to: :order, prefix: true

  before_validation :set_product_id
  after_create :decrease_product_stock
  before_create :cache_sku_properties

  after_commit :update_order_pay_amount, if: -> {
    previous_changes.include?(:pay_amount) &&
    previous_changes[:pay_amount].first != previous_changes[:pay_amount].last
  }

  def nestest_version_inventory
    @nestest_version_inventory ||= if self.updated_at >= product_inventory.updated_at
                                     product_inventory
                                   else
                                     version = product_inventory.versions.
                                       where("created_at >= ?", self.order.paid_at).
                                       order('created_at ASC').first
                                      version.present? ? version.reify(dup: true) : product_inventory
                                   end
  end

  def deal_price
    present_price - privilege_amount
  end

  def total_price
    present_price*amount
  end

  def refund_money
    if order_item_refund_id.present?
      OrderItemRefund.find(order_item_refund_id).money
    else
      '0.0'
    end
  end

  def last_refund
    order_item_refunds.reorder("created_at desc").first
  end

  def can_reapply_refund?
    return @can_reapply_refund if instance_variable_defined? '@can_reapply_refund'

    @can_reapply_refund = !order_item_refunds.where(order_state: OrdinaryOrder.states[order.state]).exists?
  end

  def count
    amount
  end

  def item_product
    product || product_inventory.product
  end

  def image_url(version=nil)
    item_product.image_url(version)
  end

  def sharing_link_node
    @sharing_link_node ||= SharingNode.find_or_create_by(
      user_id: user_id,
      product_id: product_id,
      parent_id: sharing_node_id
    )
  end

  def active_privilege_card
    if card = PrivilegeCard.find_by(user_id: user_id, seller_id: order.seller_id, actived: false)
      card.update_column(:actived, true)
    end
  end

  def recover_product_stock
    adjust_product_stock(1)
  end

  def decrease_product_stock
    adjust_product_stock(-1)
  end

  def reset_payment_info
    set_privilege_amount
    set_present_price
    set_pay_amount
  end

  def verified_time
    verify_codes.where(verified: true).first.try(:updated_at)
  end

  def total_preferential_amount
    product_inventory.privilege_amount
  end

  def total_preferential_count
    amount
  end

  def total_sharer_privilege_amount
    @total_privilege_amount ||= preferentials_privileges.sum(:total_amount)
  end

  def sharer_privilege_amount
    @sharer_privilege_amount ||= preferentials_privileges.sum(:amount)
  end

  private
  def adjust_product_stock(type, inventory_id=product_inventory_id,quantity=amount)
    if [1, -1].include?(type)
      StockMovement.sale.create!(product_inventory_id: inventory_id, quantity: quantity * type,originator: self)
      # ProductInventory.update_counters(product_inventory_id, count: amount * type)
    else
      raise 'Accept value is -1 or 1'
    end
  end

  def adjust_product_stock_with_supplier(*args)
    type = args.first
    adjust_product_stock_without_supplier(*args)
    if parent=product_inventory.try(:parent)
      adjust_product_stock_without_supplier(type, parent.id)
    end
  end
  alias_method_chain :adjust_product_stock, :supplier

  def set_privilege_amount
    self.privilege_amount = preferentials_privileges.sum(:amount)
  end

  def set_present_price
    self.present_price = if product_inventory.present?
                           product_inventory.price
                         else
                           product.price
                         end
  end

  def set_pay_amount
    self.pay_amount = deal_price * amount - preferentials_seller_bonuses.sum(:total_amount)
  end

  def update_order_pay_amount
    order.update_pay_amount
  end

  def set_product_id
    if product_inventory && product_id.blank?
      self.product_id = self.product_inventory.product_id
    end
  end

  def cache_sku_properties
    self.sku_properties = sku_attributes_str
  end
end
