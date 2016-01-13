module FilterLogic

  extend ActiveSupport::Concern

  included do
    helper_method :page_size
    helper_method :page_param
  end

  protected
  # default: order by created_at, limit 20, page 1
  # order_column to change order column and page columns
  # page_size to change limit size
  # def append_default_filter scope, opts = {}
  #   scope.recent(opts[:order_column], opts[:order_type])
  #   .paginate_by_timestamp(before_ts, after_ts, opts[:order_column])
  #   .page(page_param).per(opts[:page_size] || page_size)
  # end

  # def before_ts
  #   return Time.zone.parse(before_ts_param) if before_ts_param
  #   nil
  # end

  # def after_ts
  #   return Time.zone.parse(after_ts_param) if after_ts_param
  #   nil
  # end

  # def before_ts_param
  #   params['before_published_at']
  # end

  # def after_ts_param
  #   params["after_published_at"]
  # end

  def append_default_filter scope, opts = {}
    column_type = opts[:column_type] || 'datetime'
    case column_type.to_s
    when 'datetime'
      orderdata = params['orderdata'] ? Time.zone.parse(params['orderdata']) : nil
    when 'integer'
      orderdata = params['orderdata'] ? params['orderdata'].to_i : nil
    when 'float'
      orderdata = params['orderdata'] ? params['orderdata'].to_f : nil
    end
    if opts[:order_type].try(:upcase) == 'ASC'
      scope.recent(opts[:order_column], 'ASC')
      .paginate_by_column_name(nil ,orderdata, opts[:order_column])
      .page(page_param).per(opts[:page_size] || page_size)
    else 
      scope.recent(opts[:order_column], 'DESC')
      .paginate_by_column_name(orderdata,nil, opts[:order_column])
      .page(page_param).per(opts[:page_size] || page_size)
    end
  end

  def page_size
    (params['page_size'] && params['page_size'].to_i > 0) ? params['page_size'].to_i : 20
  end

  def page_param
    (params['page'] && params['page'].to_i > 0) ? params['page'].to_i : 1
  end

  def param_page
    params[:page] || 0
  end

end
