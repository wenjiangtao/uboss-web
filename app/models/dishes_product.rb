class DishesProduct < Product
  belongs_to :service_store
  scope :with_store, ->(store) { where(user_id: store.user_id) }

  validates_numericality_of :rebate_amount, if: "rebate_amount"
  validate :rebaste_amount_less_price
  validates_presence_of :present_price
  validates_presence_of :product_inventories
  validates_presence_of :categories

  def today_verify_code
    dishes_orders = DishesOrder.includes(:order_items).has_payed.where(order_items: {product_id: id})
    user.verify_codes.today(user).where(target_type: 'DishesOrder', target_id: dishes_orders.ids)
  end

  def total_verify_code
    dishes_orders = DishesOrder.includes(:order_items).has_payed.where(order_items: {product_id: id})
    user.verify_codes.total(user).where(target_type: 'DishesOrder', target_id: dishes_orders.ids)
  end

  def categories=(id)
    self.categories.destroy_all
    self.categories << Category.where(id: id)
  end

  def price_range
    if product_inventories.present?
      min_value = product_inventories.min_by { |a| a.price }.price
      max_value = product_inventories.max_by { |a| a.price }.price
      min_value != max_value ? "#{min_value} - #{max_value}" : min_value
    end
  end

  def rebate_amount_range
    if product_inventories.present?
      "#{product_inventories.min_by { |a| a.share_amount_total }.share_amount_total} - #{product_inventories.max_by { |a| a.share_amount_total }.share_amount_total}"
    else
      self.rebate_amount
    end
  end

  def deadline
  end

  def attr_min()
  end

  def optional_image?
    true
  end

  private
  def rebaste_amount_less_price
    errors.add(:rebate_amount, '不能大于现价') if self.rebate_amount.present? && self.rebate_amount > self.present_price
  end
end
