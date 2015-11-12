class UserAddress < ActiveRecord::Base
  include Orderable

  belongs_to :user

  validates :user, :username, :mobile, :province, :city, :building, presence: true
  validates :mobile, mobile: true

  after_save :set_default_address

  def to_s
    @province = ChinaCity.get(province) rescue province
    @city = ChinaCity.get(city) rescue city
    @area = ChinaCity.get(area) rescue area
    "#{@province}#{@city}#{@area}#{building}"
  end

  def set_default_address

    user_addresses = UserAddress.where(user_id: user_id)
    user_addresses.each do |obj|
      unless obj.id == self.id
        # binding.pry
        obj_usage = obj.usage
        obj_usage['default_post_address'] = 'false' if self.usage['default_post_address'] == 'true'
        obj_usage['default_get_address'] = 'false' if self.usage['default_get_address'] == 'true'
        obj.update_column(:usage ,obj_usage)
      end
    end
  end

end
