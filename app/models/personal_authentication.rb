class PersonalAuthentication < ActiveRecord::Base
  include AASM

  attr_accessor :mobile_auth_code
  mount_uploader :face_with_identity_card_img, ImageUploader
  mount_uploader :identity_card_front_img, ImageUploader

  validates :mobile, mobile: true
  validates_presence_of :name, :address, :mobile, :identity_card_code, :user_id
  validates_uniqueness_of :identity_card_code, :user_id
  validates :identity_card_code, identity_card_code: true

  belongs_to :user
  enum status: { posted: 0, review: 1, pass: 2, no_pass: 3 }

  aasm column: :status, enum: true, whiny_transitions: false do
    state :posted
    state :review
    state :pass, after_enter: :check_and_set_user_authenticated_to_yes
    state :no_pass, after_enter: :check_and_set_user_authenticated_to_no
  end

  def check_and_set_user_authenticated_to_yes
    user = User.find_by(id: user_id)
    if user.authenticated == 'no'
      user.authenticated = 'yes'
      user.save
      aish = AgentInviteSellerHistroy.find_by(mobile: user.login)
      aish.update(status: 2) if aish.present? && user.agent_id == aish.agent_id
    end
  end

  def check_and_set_user_authenticated_to_no # 检查企业信息验证情况,若已经通过,则保存用户验证状态为通过;反之则设为未验证
    user = User.find_by(id: self.user_id)
    if EnterpriseAuthentication.where(user_id: self.user_id, status: 2).exists?
      #DO_NOTHING
    else
      user.authenticated = 'no'
      user.save
      aish = AgentInviteSellerHistroy.find_by(mobile: user.login)
      if aish.present? && user.agent_id == aish.agent_id
        aish.update(status: 1)
      elsif aish.present?
        aish.update(status: 0)
      end
    end
  end

  def self.posted
    PersonalAuthentication.where(status: 0)
  end
  def self.review
    PersonalAuthentication.where(status: 1)
  end
  def self.pass
    PersonalAuthentication.where(status: 2)
  end
  def self.no_pass
    PersonalAuthentication.where(status: 3)
  end
end
