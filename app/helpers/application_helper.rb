module ApplicationHelper

  def uboss_mall?(seller)
    %w(19800000888).include? seller.login.to_s
  end

  def product_show?
    (controller_name == 'products' || controller_name == 'service_products') && action_name == 'show'
  end

  def countdown_time(time)
    time.strftime('%Y/%m/%d %H:%M:%S')
  end

  def qrcode_image_tag(text, opts = {})
    html_opts = opts.delete(:html) || {}
    opts = {
      text: text
    }.merge(opts)
    image_tag request_qrcode_url(opts), html_opts
  end

  def has_flash
    [:alert, :success, :notice, :info,:error].any? { |key| flash.key?(key) }
  end

  def horizon_form_for(record, options = {}, &block)
    options = options.merge(
      html: { class: 'form-horizontal' },
      wrapper: :horizontal_form,
      wrapper_mappings: {
        check_boxes: :horizontal_radio_and_checkboxes,
        radio_buttons: :horizontal_radio_and_checkboxes,
        file: :horizontal_file_input,
        boolean: :horizontal_boolean
      }
    )
    simple_form_for(record, options, &block)
  end

  def alert_box(message, opts = {})
    alert_type = opts.delete(:type) || 'alert-info'
    content_tag :div, class:"container" do
      content_tag :div, message, class: "alert #{alert_type}", role: 'alert', data: {dismiss: 'alert'} do
        [
          content_tag(:button, class: 'close') do
            content_tag(:span, '×')
          end,
          message
        ].join.html_safe
      end
    end
  end

  def nav_group(name, &block)
    list = capture(&block)
    return '' if list.blank?

    text = t(name, scope: "nav_groups", default: name.to_s.humanize)
    active_status = /[^_\-a-aA-Z]active/.match(list) ? "active" : ""

    dropdown_list_string = <<-HTML
    <li class="dropdown #{active_status}">
      <a href="#" class="dropdown-toggle" data-toggle="dropdown">#{text}<span class="caret"></span></a>
      <ul class="dropdown-menu" role="menu">#{list}</ul>
    </li>
    HTML
    dropdown_list_string.html_safe
  end

  def li_link name, path, opts = {}
    i18n_key = opts.delete(:i18n_key)
    active_class = active?(opts.delete(:another_active_name) || name)
    content_tag :li, { class: active_class.to_s }.merge(opts) do
      content_tag :a, I18n.t("li_link.#{i18n_key || name}"), href: path
    end
  end

  def can_li_link operate, resource, path, opt = {}
    link_name = opt[:link_name]
    link_name ||= resource.is_a?(Class) ? resource.name.tableize : resource
    li_link(link_name, path, opt) if can?(operate, resource)
  end

  def active? chapter
    if controller_name == chapter.to_s
      'active'
    end
  end

  def sharing_meta_tags(product, sharing_link_node = nil)
    meta_tags = {
      sharing_title:  product_sharing_title(product),
      sharing_desc:   product_sharing_desc(product),
      sharing_imgurl: product.image_url(:thumb),
      sharing_link:   product_sharing_link(product, sharing_link_node)
    }
    meta_tags.collect do |key, value|
      content_tag :meta, '', name: key, content: value
    end.join.html_safe
  end

  def store_sharing_meta_tags(seller, sharing_link_node = nil, redirect = nil)
    meta_tags = {
      sharing_title:  "【#{seller.store_identify}】好货不断，通过分享购买更有优惠惊喜！",
      sharing_desc:   "在我这儿，谁还会用市场价购买啊？",
      sharing_imgurl: seller.avatar_url(:thumb),
      sharing_link:  store_sharing_link(seller, sharing_link_node, redirect),
    }
    meta_tags.collect do |key, value|
      content_tag :meta, '', name: key, content: value
    end.join.html_safe
  end

  def luffy_meta_tags(opts={})
    meta_tags = {
      sharing_title:  opts[:title] || 'UBOSS商城 | 基于人，超乎想象',
      sharing_desc:   opts[:desc],
      sharing_imgurl: opts[:imgurl] || image_url('favicon-lg.png'),
      sharing_link:  opts[:link] || root_url
    }
    meta_tags.collect do |key, value|
      content_tag :meta, '', name: key, content: value
    end.join.html_safe
  end

  def displayable_class(boolean_value)
    boolean_value ? '' : 'hidden'
  end

  def abled_class(boolean_value)
    boolean_value ? '' : 'disabled'
  end

  def valid_order_box_class(boolean_value)
    boolean_value ? 'invalid-box' : 'valid-box'
  end

  def seo_meta_tag
    [
      content_tag(:meta, '', name: :Keywords,    content: Rails.application.secrets.metas['keywords']),
      content_tag(:meta, '', name: :description, content: Rails.application.secrets.metas["description"])
    ].join.html_safe
  end

end
