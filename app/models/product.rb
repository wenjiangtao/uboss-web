# encoding:utf-8
class Product < ActiveRecord::Base
  DataCalculateWay = { 0 => '按金额', 1 => '按售价比例' }
  DataBuyerPay = { true => '买家付款', false => '卖家付款' }

  validates_presence_of :user_id, :name

  belongs_to :user
  has_one :asset_img, class_name: 'AssetImg', dependent: :destroy, as: :resource
  has_many :product_share_issue, dependent: :destroy
  has_many :order_items

  delegate :image_url, to: :asset_img, allow_nil: true

  before_create :generate_code
  before_save :calculates_before_save

  def generate_code
    loop do
      self.code = SecureRandom.hex(10)
      break if !Product.find_by(code: code)
    end
  end

  def calculates_before_save
    calculate_share_amount_total
    set_share_rate
    calculate_shares
  end

  def calculate_share_amount_total # 如果按比例进行分成，将分成比例换算成实质分成总金额
    if calculate_way == 1
      self.share_amount_total = ('%.2f' % (present_price * share_rate_total * 0.01)).to_f # 价格×总分成比例=总分成金额
    end
  end

  def set_share_rate(*args) # 设置分成比例
    3.times do |index|
      rate = args[index] || get_shraing_rate(has_share_lv, index+1)
      self.__send__("share_rate_lv_#{index + 1}=", rate)
    end
  end

  def calculate_shares # 计算具体的分成金额
    if has_share_lv != 0 # 参与分成的情况
      assigned_total = 0

      3.times do |index|
        level = index + 1
        amount = ('%.2f' % (share_amount_total * self["share_rate_lv_#{level}"])).to_f
        self.__send__("share_amount_lv_#{level}=", amount)
        assigned_total += amount
      end

      self.privilege_amount = share_amount_total - assigned_total
    end
  end

  def total_sells
    order_items.joins(:order).where(orders: {state: 4}).sum(:amount)
  end

  def self.total_sells(product_id) #商品总销量
    Product.find(product_id).total_sells
  end

  private
  def get_shraing_rate(sharing_level, rate_level)
    Rails.application.secrets.product_sharing["level#{sharing_level}"].try(:[], "rate#{rate_level}").to_f
  end

end
