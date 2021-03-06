class ServiceOrder < Order

  enum state: { unpay: 0, payed: 1, closed: 5, completed: 6 }

  scope :has_payed, -> { where(state: [1, 6]) }
  has_many :verify_codes, through: :order_items
  scope :unevaluate, -> { completed.joins("inner join order_items on orders.id = order_items.order_id left join evaluations on order_items.id = evaluations.order_item_id or orders.id = evaluations.order_id").where(evaluations: {id: nil}).uniq }

  aasm column: :state, enum: true, skip_validation_on_save: true, whiny_transitions: false do
    state :unpay
    state :payed,     after_enter: :invoke_service_order_payed_job
    state :completed, after_enter: :fill_completed_at
    state :closed

    event :pay do
      transitions from: :unpay, to: :payed
    end
    event :close do
      transitions from: :unpay, to: :closed
    end
    event :complete do
      transitions from: :payed, to: :completed
    end
  end

  # 增加未评价状态
  def state
    super == "completed" && order_item.evaluations.size == 0 ? "unevaluate" : super
  end

  def paid_and_expensed?
    (completed? || state == 'unevaluate') && !verify_codes.any? { |verify_code| !verify_code.verified }
  end

  def order_item
    order_items.first
  end

  def check_completed
    if VerifyCode.where(target: self.order_item, verified: false).blank?
      may_complete? && completed!
    end
  end

  private

  def invoke_service_order_payed_job
    order_item.amount.times { order_item.verify_codes.create!(user_id: self.seller_id) }
    ServiceOrderPayedJob.perform_later(self)
  end

  def create_privilege_card_if_none
    PrivilegeCard.find_or_active_card(user_id, seller.id)
  end

end
