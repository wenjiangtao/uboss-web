class AutoSignOrderJob < ActiveJob::Base

  queue_as :auto_sign_order

  include Loggerable

  AUTOSIGN_TIME = Rails.env.production? ? 9.days.freeze : 30.minutes.freeze

  def perform
    OrdinaryOrder.joins(:order_charge).shiped.
      where("orders.shiped_at <= ? AND (order_charges.paid_at BETWEEN '2016-02-06' AND '2016-02-12')", Time.now - AUTOSIGN_TIME - 6.days).find_each do |ordinary_order|
      sign_order_if_no_refunds(ordinary_order)
    end

    OrdinaryOrder.joins(:order_charge).shiped.
      where("orders.shiped_at <= ? AND (order_charges.paid_at NOT BETWEEN '2016-02-06' AND '2016-02-12')", Time.now - AUTOSIGN_TIME).
      find_each do |ordinary_order|
      sign_order_if_no_refunds(ordinary_order)
    end
  end

  private

  def sign_order_if_no_refunds(ordinary_order)
    if ordinary_order.order_items.joins(:order_item_refunds).merge(OrderItemRefund.progresses).exists?
      return false
    end

    if ordinary_order.may_sign?
      logger.info "Auto Sign Order SUCCESS, number: #{ordinary_order.number}"
      ordinary_order.sign!
    end
  rescue => e
    logger.error "Auto Sign Order FAIL, number: #{ordinary_order.number}, ERROR: #{e.message}"
    Airbrake.notify_or_ignore(
      e,
      parameters: {order_number: ordinary_order.number},
      cgi_data: ENV.to_hash
    )
  end

end
