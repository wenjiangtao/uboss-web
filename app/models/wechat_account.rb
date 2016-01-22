class WechatAccount < ActiveRecord::Base
  # It will auto generate weixin token and secret
  #include WeixinRailsMiddleware::AutoGenerateWeixinTokenSecretKey

  validates_presence_of :name
  validates_uniqueness_of :weixin_secret_key

end