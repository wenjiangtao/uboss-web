#encoding:utf-8
#商品展示
class ProductsController < MobileController
  layout "mobile"
	def index
    @products = Product.order("updated_at DESC").page(params[:page] || 1).per(10)
	end

	def show
    @product = Product.find_by_id(params[:id])
    redirect_to :action=>:index unless @product.present?
	end

  def save_mobile
    puts params
    redirect_to :action=>:index
  end

end