class StoresController < ApplicationController
  include SharingResource

  layout 'mobile'

  before_action :login_app, only: [:show]
  before_action :authenticate_user!, only: [:favours]
  before_action :set_seller, only: [:show, :hots, :favours]
  before_action :get_sharing_node, :set_sharing_link_node, only: [:show, :hots]

  def index
    @products = append_default_filter Product.published.includes(:asset_img), order_column: :updated_at
    @hot_products = []
    @products.each do |product|
      @hot_products << product if @hot_products.empty?
      product.total_sells
    end
    @uboss_seller = User.find_by(login: '19812345678')
    @recommend_ids = @uboss_seller.store_short_description.split(',')
    @stores = User.where(id: @recommend_ids)
  end

  def show
    @products = append_default_filter @seller.products.published, order_column: :updated_at
    @products_order_with_sales = Product.published.includes(:asset_img).where(id: Statistic.where(resource_type: 'product').order('integer_count').page(params[:page] || 1).collect(&:resource_id))
    @hots = @seller.products.hots.recent.limit(3)
    @categories = Category.where(use_in_store: true, user_id: @seller.id).order('use_in_store_at')
    render_product_partial_or_page
  end

  def hots
    @products = append_default_filter @seller.products.hots, order_column: :updated_at
    render_product_partial_or_page
  end

  def favours
    @products = append_default_filter current_user.favoured_products.where(user_id: @seller.id)
    render_product_partial_or_page
  end

  private

  def render_product_partial_or_page
    if request.xhr?
      render partial: 'product', collection: @products
    else
      render :show
    end
  end

  def set_seller
    @seller = User.find(params[:id])
  end
end
