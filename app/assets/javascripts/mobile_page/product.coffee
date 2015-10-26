$ ->

  @flashPopContent = (html_str) ->
    flash_content = $('<div class="pop-alert flash_css text-center"><div class="pop-content"></div>')
    flash_content.appendTo('body')
    flash_content.find('.pop-content').append(html_str)
    setTimeout ->
      flash_content.remove()
    , 3000

  $(document).on 'ajaxSuccess', '.like-product-btn', (event, xhr, settings, data) ->
    if data.favoured
      $(this).addClass('active')
      flashPopContent('<div class="pop-text">您喜欢了该商品，可以在店铺主页<br/>我的喜欢模块找到本商品</div>')
    else
      $(this).removeClass('active')
      flashPopContent('<div class="pop-text line-2 gray">您取消了该喜欢商品</div>')

  $(document).on 'ajaxError', '.like-product-btn', () ->
    alert "操作失败"

  $('#show_inventory_cart').on 'click', ->
    $('#submit_way').val('cart')
    showInventory()

  $('#show_inventory').on 'click', ->
    $('#submit_way').val('buy')
    showInventory()

  showInventory = ->
    if $('#inventory').length > 0
      $('#inventory').removeClass('hidden')
      $('.fixed-container').css('-webkit-filter', 'blur(3px)')
      $('html').addClass('lock')
      product_inventory_property_buy_now_option.render('','',$('#submit_way').val(),$('#product_id').val())

  $('.count-box .count_min').on 'click',->
    num=parseInt($('.count-box .count_num').val())
    if num < 2
      alert('数量必须大于1')
      $('.count-box .count_num').val(1)
      $('#count_amount').val(1)
    else
      $('.count-box .count_num').val(num-1)
      $('#count_amount').val(num-1)

  $('.count-box .count_plus').on 'click',->
    num=parseInt($('.count-box .count_num').val())
    $('.count-box .count_num').val(num+1)
    $('#count_amount').val(num+1)

  $.fn.onlyNum = () ->
    $(this).keyup () ->
      $this = $(this)
      this.value = this.value.replace(/[^\d]/g, '')

  # 限制只能输入数字
  $.fn.onlyNum = () ->
    $(this).keypress (event) ->
      eventObj = event || e
      keyCode = eventObj.keyCode || eventObj.which
      if (keyCode >= 48 && keyCode <= 57)
        return true
      else
        return false
    .focus () ->
      this.style.imeMode = 'disabled' # 禁用输入法
    .bind "paste", () ->              # 禁用粘贴
      return false

  $(".count-box .count_num").on 'change',->
    $this = $(this)
    this.value = this.value.replace(/[^\d]/g, '')
    $('#count_amount').val(this.value)
    if this.value == '' || this.value == "0"
      this.value = 1
      $('#count_amount').val(1)

  $(".count-box .count_num").onlyNum()
