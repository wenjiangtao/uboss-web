class OrdersController < ApplicationController

  before_action :authenticate_user!, only: [:new, :pay]
  before_action :find_order, only: [:show, :pay, :pay_complete, :received]

  def show
    @order_item = @order.order_items.first
    @product = @order_item.product
    if @order.unpay?
      @order_charge = ChargeService.find_or_create_charge(@order, remote_ip: request.ip)
      @pay_p = {
        appId: WxPay.appid,
        timeStamp: Time.now.to_i.to_s,
        nonceStr: SecureRandom.hex,
        package: "prepay_id=#{@order_charge.prepay_id}",
        signType: "MD5"
      }
      @pay_sign = WxPay::Sign.generate(@pay_p)
    end
  end

  def new
    @order_form = OrderForm.new(
      buyer: current_user,
      product_id: params[:product_id],
      sharing_code: get_product_sharing_code(params[:product_id])
    )
    @product = @order_form.product
    if current_user && current_user.default_address
      @order_form.user_address_id = current_user.default_address.id
    end
  end

  def create
    @order_form = OrderForm.new(order_params.merge(buyer: current_user))
    @order_form.sharing_code = get_product_sharing_code(@order_form.product_id)
    if @order_form.save
      sign_in(@order_form.buyer) if current_user.blank?
      redirect_to order_path(@order_form.order)
    else
      render :new
    end
  end

  def pay_complete
    @order.check_paid if @order.unpay?
  end

  def received
    @order.state = 1
    if @order.save
      flash[:success] = '已确认收货'
      redirect_to controller: :evaluations, action: :new, id: @order.order_items.first.id
    end
  end

  private

  def order_params
    params.require(:order_form).permit(OrderForm::ATTRIBUTES)
  end

  def find_order
    @order = Order.find(params[:id])
  end
end
