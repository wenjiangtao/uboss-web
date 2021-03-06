class VerifyCodesController < ApplicationController

  layout 'mobile'

  before_action :authenticate_user!

  def index
    @service_orders = ServiceOrder.where(user_id: current_user.id).payed.includes(order_items: { product_inventory: { product: :asset_img } })
  end

  def show
    if params[:type] == 'dishes'
      @verify_codes = VerifyCode.where(target_type: 'DishesOrder', target_id: params[:id])
    else
      order_item = OrderItem.find(params[:id])
      @verify_codes = order_item.verify_codes
    end
  end

  def lotteries
    @activity_prizes = ActivityPrize.where(prize_winner_id: current_user.id).order('created_at DESC')
  end

  def lottery_detail
    @activity_prize = ActivityPrize.find(params[:id])
    @verify_code = @activity_prize.verify_code
    @activity_info = @activity_prize.activity_info
    if !@verify_code.expired && !@verify_code.verified
      @hint = '未使用'
      @css_class = ''
    elsif !@verify_code.expired
      @hint = '已消费'
      @css_class = 'gray-bg'
    else
      @hint = '已过期'
      @css_class = 'gray-bg'
    end
  end

end
