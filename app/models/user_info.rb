class UserInfo < ActiveRecord::Base

  include Imagable

  belongs_to :user

  def store_title
    if store_name.blank?
      nil
    else
      short_desc = store_short_description.blank? ? nil : store_short_description
      [store_name, short_desc].compact.join(" | ")
    end
  end

  def store_identify
    store_name || user.nickname || user.mobile || 'UBOSS商家'
  end

  mount_uploader :store_banner_one, ImageUploader
  mount_uploader :store_banner_two, ImageUploader
  mount_uploader :store_banner_thr, ImageUploader
  mount_uploader :store_cover,      ImageUploader

  compatible_with_form_api_images :store_banner_one, :store_banner_two, :store_banner_thr, :store_cover

  scope :ordinary_store, -> { where(type: 'OrdinaryStore') }
  scope :service_store, -> { where(type: 'ServiceStore') }

  def good_reputation_rate
    return @sharer_good_reputation_rate if @sharer_good_reputation_rate
    o_store = self.user.ordinary_store
    s_store = self.user.service_store
    good = o_store.best_evaluation.to_i + o_store.better_evaluation.to_i + o_store.good_evaluation.to_i + s_store.best_evaluation.to_i + s_store.better_evaluation.to_i + s_store.good_evaluation.to_i

    @sharer_good_reputation_rate = if total_reputations > 0
                                     good * 100 / total_reputations
                                   else
                                     100
                                   end
  end

  def total_reputations
    o_store = self.user.ordinary_store
    s_store = self.user.service_store
    @total_reputations ||= (o_store.good_evaluation.to_i + o_store.bad_evaluation.to_i + o_store.better_evaluation.to_i + o_store.best_evaluation.to_i + o_store.worst_evaluation.to_i + s_store.good_evaluation.to_i + s_store.bad_evaluation.to_i + s_store.better_evaluation.to_i + s_store.best_evaluation.to_i + s_store.worst_evaluation.to_i)
  end
end
