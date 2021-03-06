$ ->

  $('#address').on 'click', ->
    $('#address-list-box').removeClass('hidden')
    $('html,body').addClass('lock')

  $('#address-list-box .close').on 'click',->
    $('#address-list-box').addClass('hidden')
    $('html,body').removeClass('lock')

  $('#address-more').on 'click', ->
    $('#address-new').removeClass('hidden')

  $('#address-new .close').on 'click',->
    $('#address-new').addClass('hidden')

  $('#address-list-box .add_line1').on 'click', ()->
    $('#order_form_user_address_id').val($(this).data('id'))
    fillNewOrderAddressInfo(
      $(this).find('.adr-user').text(),
      $(this).find('.adr-mobile').text(),
      $(this).find('.adr-detail').text()
    )
    $('#address-list-box').addClass('hidden')
    $('html,body').removeClass('lock')
    setOrderRelativeData()
    flashPopContent('<div class="pop-text">修改收货地址后请重新确认订单信息</div>')

  $('#address-new .use-new-addr-btn').on 'click', (event)->
    event.preventDefault()
    user = $('#order_form_deliver_username').val()
    mobile = $('#order_form_deliver_mobile').val()
    province_val = $('.city-select#province').val()
    province_str = ".city-select#province option[value$=\"#{province_val}\"]"
    province = $(province_str).text()
    city_val = $('.city-select#city').val()
    city_str = ".city-select#city option[value$=\"#{city_val}\"]"
    city = $(city_str).text()
    area_val = $('.city-select#area').val()
    area_str = ".city-select#area option[value$=\"#{area_val}\"]"
    area = $(area_str).text()
    building = $('#order_form_building').val()
    if !!user and !!mobile and !!province and !!city and !! area and !!building
      if UBoss.chopper.valifyMobile(mobile)
        detail = "#{province}#{city}#{area}#{building}"
        fillNewOrderAddressInfo(user, mobile, detail)
        $('#order_form_user_address_id').val('')
        $('#address-list-box').addClass('hidden')
        $('html,body').removeClass('lock')
        $('#address-new').addClass('hidden')
        setOrderRelativeData()
        flashPopContent('<div class="pop-text">修改收货地址后请重新确认订单信息</div>')
        $(".accunt_adilbtn").removeAttr('disabled')
      else
        alert('手机号无效')
    else
      flashPopContent('<div class="pop-text">请填写完整收货信息</div>')

  fillNewOrderAddressInfo = (user, mobile, detail)->
    $('#address .address-box .adr-user').text(user)
    $('#address .address-box .adr-mobile').text(mobile)
    $('#address .address-box .adr-detail').text(detail)
    $('#address .address-box').removeClass('hidden')
    $('.none-address-box').hide()

  # 获取有效商品、无效商品、运费等信息(收货地址改变) XXX===========
  setOrderRelativeData = ->
    $.ajax
      url: '/orders/change_address'
      type: 'POST'
      data: {
        cart_id: $('#order_form_cart_id').val(),
        product_id: $('#order_form_product_id').val(),
        product_inventory_id: $('#order_form_product_inventory_id').val(),
        count: $('#order_form_amount').val(),
        user_address_id: $('#order_form_user_address_id').val(),
        province: $('#province').val()
      }
      success: (res) ->
        if res['status'] == "ok"
          refreshInvalidItems(res['invalid_items'])
          refreshValidItemsList(res['valid_item_ids'])
          setOrderListVisible()
          setSingleOrderShipPrice(res['ship_price'])
          setSingleOrderPrivilegeAmount()
          setSingleOrderTotalPrice()
          setOrderTotalPrice()
          setSubmitOrderBtn()
        else
          flashPopContent('<div class="pop-text">操作错误</div>')
          location.reload()
      error: (data, status, e) ->
        flashPopContent('<div class="pop-text">操作错误</div>')
        location.reload()

  # 单商铺修改运费
  setSingleOrderShipPrice = (ship_price_arr) ->
    $.each(ship_price_arr , () ->
      $('.ship_price_'+this[0]).html('<strong></strong>￥ '+this[1])
      $('.ship_price_'+this[0]).data("ship-price", this[1])
    )

  # 单商铺计算优惠
  setSingleOrderPrivilegeAmount = ->
    $('.valid-order-list.valid-list').each ->
      $this = $(this)
      privilege_amount = 0.0
      seller_bonus = 0.0
      $this.find('.order-box.valid-box').each ->
        amount = parseFloat($(this).find('meta[itemprop="privilege_bonus"]').attr('content'))
        seller_amount = parseFloat($(this).find('meta[itemprop="seller_bonus"]').attr('content'))
        num   = parseInt($(this).find('.num').data('num'))
        privilege_amount = floatAdd(privilege_amount, floatMul(amount, num))
        seller_bonus = floatAdd(seller_bonus, seller_amount)
      $privilege_amount = $this.find('.order-privilege-amount')
      $friend_info = $privilege_amount.closest('.friend-info')
      $privilege_amount.text(privilege_amount)
      $seller_bonus_amount = $this.find('.order-seller-bonus')
      $seller_bonus_amount.text(seller_bonus)
      $seller_bonus_info = $seller_bonus_amount.closest('.friend-info')
      if seller_bonus == 0
        $seller_bonus_info.removeClass('hidden').addClass('hidden')
      else
        $seller_bonus_info.removeClass('hidden')
      if parseFloat($privilege_amount.text()) == 0
        $friend_info.removeClass('hidden').addClass('hidden')
        $friend_info.next().css('border-top', '0px')
      else
        $friend_info.removeClass('hidden')


  # 单商铺计算总价
  setSingleOrderTotalPrice = ->
    $('.valid-order-list.valid-list').each ->
      $this = $(this)
      total_price = 0.0
      $this.find('.order-box.valid-box').each ->
        num   = parseInt($(this).find('.num').data('num'))
        price = parseFloat($(this).find('.product-price').text())
        total_price = floatAdd(total_price, floatMul(price, num))
      ship_price = parseFloat($this.find('.freight-box>span').data('ship-price'))
      privilege_amount = parseFloat($this.find('.order-privilege-amount').text()) || 0.0
      seller_bonus = parseFloat($this.find('.order-seller-bonus').text()) || 0.0
      total_price = floatAdd(total_price, floatSub(ship_price, privilege_amount))
      total_price = floatSub(total_price, seller_bonus)
      $this.find('.price-box>span').data('total-price', total_price)
      $this.find('.price-box>span').text('￥ ' + total_price)

  # 总价
  setOrderTotalPrice = ->
    total_price = 0.0
    privelege_price = 0.0
    $('.valid-order-list.valid-list').find('.price-box').each ->
      total_price = floatAdd(total_price, parseFloat($(this).find('span').data('total-price')))
      privelege_price = floatAdd(privelege_price, (parseFloat($(this).parent().find('.order-privilege-amount').text()) || 0.0))
      privelege_price = floatAdd(privelege_price, (parseFloat($(this).parent().find('.order-seller-bonus').text()) || 0.0))
    $('#total_price').text(total_price)
    $('.order-price').find('small').text('共优惠'+privelege_price+'元')

  setOrderListVisible = ->
    $('.order-list').each ->
      $this = $(this)
      if $this.find('.order-box.valid-box').length == 0
        $this.removeClass('valid-list').addClass('invalid-list')
      else
        $this.removeClass('invalid-list').addClass('valid-list')

  setSubmitOrderBtn = ->
    $cart_btn = $('.order-price').find('.cart-btn')
    if $('.order-list.valid-order-list.valid-list').length == 0
      $cart_btn.attr('disabled', true)
    else
      $cart_btn.removeAttr('disabled')


  # 更新有效的商品列表
  refreshValidItemsList = (valid_item_ids) ->
    $('.valid-order-list').find('.order-box').each ->
      if valid_item_ids
        item_id = $(this).data('item-id')
        if inArray(valid_item_ids, item_id)
          $(this).removeClass('invalid-box').addClass('valid-box')
        else
          $(this).removeClass('valid-box').addClass('invalid-box')
      else
        if $('.dead-items').find('.order-box').length == 0
          $(this).removeClass('invalid-box').addClass('valid-box')
        else
          $(this).removeClass('valid-box').addClass('invalid-box')

  # 检查元素是否在数组内
  inArray = (arr, item) ->
    for a in arr
      if a == item
        return true
        break

  # 更新无效的商品列表
  refreshInvalidItems = (invalid_items) ->
    html = ''
    if invalid_items.length == 0
    else
      html += '<div class="seller-box"><div class="text-cut">失效宝贝</div></div>'
      for item in invalid_items
        html += '<div class="order-box valid-box"> <div class="cover"><img alt="-" src="' +
        item['image_url'] +
        '"></div> <div class="content"> <div class="price"> <p class="gray-color">￥<span class="product-price">' +
        item['price'] +
        '</span></p> <p class="gray-color num" data-num="1">x ' +
        item['count'] +
        '</p> </div> <p class="name">' +
        item['name'] +
        '</p> <p class="info">' +
        item['sku'] +
        '</p><p class="like-color text-break"><small>抱歉，该商品在收货地址内不可售，请重新选择收货地址</small></p></div></div>'
    $(".dead-items").empty().append(html)

  if $('#total_price').length != 0 && location.pathname == '/orders/new'
    setOrderRelativeData()
