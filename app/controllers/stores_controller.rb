class StoresController < ApplicationController
  include SharingResource

  layout 'mobile'

  before_action :login_app, only: [:show]
  before_action :authenticate_user!, only: [:favours]
  before_action :set_seller, only: [:show, :hots, :favours]
  before_action :get_sharing_node, :set_sharing_link_node, only: [:show, :hots]

  def index
    @uboss_seller = User.find_by(login: '19812345678')
    @recommend_ids = @uboss_seller.store_short_description.split(',')
    @stores = User.where(id: @recommend_ids)
  end

  def show
    @order_column_name = params[:order].present? ? params[:order] : 'comprehensive_order'
    @products = append_default_filter_for_store_show @seller.products.published.includes(:asset_img), order_column: @order_column_name, page_size: 6
    @hots = @seller.products.hots.recent.limit(3)
    @categories = Category.where(use_in_store: true, user_id: @seller.id).order('use_in_store_at')
    render_product_partial_or_page
  end

  def hots
    @products = append_default_filter @seller.products.hots.includes(:asset_img), order_column: :updated_at
    render_product_partial_or_page
  end

  def favours
    @order_column_name = 'updated_at'
    @products = append_default_filter current_user.favoured_products.where(user_id: @seller.id).includes(:asset_img)
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

  def append_default_filter_for_store_show(scope, opts)
    append_default_filter scope, order_column: opts[:order_column], order_type: order_column_type(opts[:order_column])[:order], column_type: order_column_type(opts[:order_column])[:type], page_size: opts[:page_size]
  end

  def order_column_type(order_column)
    case order_column.to_s
    when 'published_at'
      { order: 'DESC', type: :datetime }
    when 'sales_amount_order'
      { order: 'ASC', type: :integer }
    when 'comprehensive_order'
      { order: 'ASC', type: :integer }
    end
  end
end
