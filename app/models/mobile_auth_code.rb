class MobileAuthCode < ActiveRecord::Base

  validates :mobile, presence: true, uniqueness: true, mobile: true
  validates :code, :expire_at, presence: true

  before_validation :generate_code, :set_expire_time
  after_save :send_code

  def self.auth_code(mobile, code) #验证
    auth_code = MobileAuthCode.
      where('expire_at > ?', Time.now).
      find_by(mobile: mobile, code: code)

    if auth_code.blank?
      false
    else
      auth_code.destroy
      true
    end
  end

  def self.send_captcha_with_mobile(mobile)
    auth_code = MobileAuthCode.find_or_initialize_by(mobile: mobile)
    auth_code.regenerate_code unless auth_code.new_record?
    auth_code.save
  end

	def generate_code #生成验证码
    self.code ||= rand(9999..100000).to_s.ljust(5,'0')
  end

  def set_expire_time #设定过期时间
    self.expire_at ||= Time.now + 30.minute
  end

	def regenerate_code
    self.code = rand(9999..100000).to_s.ljust(5,'0')
    self.expire_at = Time.now + 30.minute
    self
  end

  def send_sms(tpl_id=1) # 发送短信
    return {'msg'=> 'error',"detail"=>"电话号码不能为空"} if mobile.blank?
    return {'msg'=> 'error',"detail"=>"内容不能为空"} if code.blank?
    begin
      sms = ChinaSMS.to(mobile, {code:code,company:'优来吧UBoss'}, tpl_id: tpl_id)
      return "OK" if sms['msg'] == "OK"
      return sms
    rescue Exception => e
      return e.message
    end
  end

  def send_code # 发送验证码
    result = send_sms
    puts result
    if result == "OK"
      return true
    else
      return false
    end
  end
end
