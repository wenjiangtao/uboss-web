class AgencyOrder < OrdinaryOrder
  has_one :purchase_order, foreign_key: :order_id
  after_create :create_purchase_order

  def create_purchase_order
    PurchaseOrder.create(order: self)
  end

  def after_completed
    purchase_order.complete!
  end

  def after_payed
    purchase_order.pay!
  end

  def after_close
    purchase_order.close!
  end

  def after_signed
    purchase_order.sign!
  end
end
