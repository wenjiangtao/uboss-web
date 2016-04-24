class Admin::ShopsController < AdminController
  authorize_resource
  before_action :set_operator
  before_action :set_shop, only: [:show, :edit, :update, :destroy]

  # GET /admin/shops
  # GET /admin/shops.json
  def index
    %w(today all).include?(params[:segment]) or params[:segment] = 'today'
    @scope = scope.joins(user: :orders).merge(Order.have_paid)
    @shops = scope.includes(:user).page(params[:page])
  end

  def added
    @shops = scope.includes(:user, :clerk).page(params[:page])
  end

  # GET /admin/shops/1
  # GET /admin/shops/1.json
  def show
  end

  # GET /admin/shops/new
  def new
    @shop = scope.new
    @shop.build_clerk
  end

  # GET /admin/shops/1/edit
  def edit
  end

  # POST /admin/shops
  # POST /admin/shops.json
  def create
    @shop = scope.new(shop_params)

    respond_to do |format|
      if @shop.save
        flash[:success] = "创建成功"
        format.html { redirect_to action: :added }
      else
        flash.now[:error] = @shop.errors.full_messages.join("<br/>")
        format.html { render :new }
      end
    end
  end

  private
    def scope
      @operator.shops
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_shop
      @shop = scope.find(params[:id])
    end

    def set_operator
      @operator = Operator.where(user_id: current_user.id).first!
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def shop_params
      params.require(:shop).permit(:avatar, :name, :mobile, :login, :address, :province, :city, :district, clerk: [:name, :mobile])
    end
end