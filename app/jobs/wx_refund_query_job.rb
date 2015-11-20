class WxRefundQueryJob < ActiveJob::Base
  queue_as :default

  def perform
    RefundRecord.where(applied_status: 'SUCCESS', refund_status: [nil, 'PROCESSING'])
      .where("applied_at <= ? and applied_at >= ?", Time.now - 20.minutes, Time.now - 15.days).find_each(batch_size: 500) do |record|

      res = WxPay::Service.invoke_refundquery({ out_trade_no: record.out_refund_no })
      record.query_count += 1
      record.query_content = res

      record.transaction do
        if res.success?
          if res['refund_status_0'] == 'SUCCESS'
            refund = record.order_item_refund
            refund.may_finish? && refund.finish!
            refund.order_item.update(order_item_refund_id: refund.id)
            record.refunded_at    = Time.current
          elsif res['refund_status_0'] == 'NOTSURE'
            WxRefundJob.perform_later(refund)
          end

          record.refund_status  = res['refund_status_0']
          record.refund_channel = res['refund_channel_0']
        end
        record.save
      end
    end
  end

end
