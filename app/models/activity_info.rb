class ActivityInfo < ActiveRecord::Base
  include Descriptiontable

  has_one_content name: :description

  belongs_to :promotion_activity
  has_many   :activity_prize, dependent: :destroy
  has_many   :activity_draw_records, dependent: :destroy
  validates :activity_type, :name, :price, :expiry_days, :win_count, :win_rate, presence: true
  validates :activity_type, inclusion: { in: %w(live share) }
  validates :win_rate, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :win_count, numericality: { greater_than: 0 }
  validates :promotion_activity_id, uniqueness: { scope: :activity_type }

  def prize_arr
    if activity_type == 'live'
      @win_count = win_count.to_f
    elsif activity_type == 'share'
      @win_count = win_count / 2
    else
      raise RuntimeError.new('unexpected activity_type')
    end
    @win_rate = win_rate.to_f * 0.01
    total = @win_count / @win_rate
    prize_step = (total / @win_count).to_i
    arr = []
    i = 1
    win_count.times do
      arr << i
      i += prize_step
    end

    arr
  end

  def draw_share_prize(winner_id, sharer_id)
    if !User.find_by_id(winner_id)
      raise ArgumentError.new('winner not found')
    elsif !User.find_by_id(sharer_id)
      raise ArgumentError.new('sharer not found')
    elsif promotion_activity.status != 'published'
      raise RuntimeError.new('activity not published or closed')
    elsif activity_type != 'share'
      raise RuntimeError.new('wrong method used')
    elsif ActivityDrawRecord.find_by(user_id: winner_id, sharer_id: sharer_id, activity_info_id: id).present?
      raise RepeatedActionError.new('you have already drawed prize')
    else
      ActivityInfo.transaction do
        ActivityInfo.lock
        update!(draw_count: draw_count ? (draw_count + 1) : 1)
        winner_activity_prize, sharer_activity_prize = nil
        if prize_arr.include?(draw_count) # 本次draw_count在中奖数组中
          winner_verify_code_id = VerifyCode.create!.id
          sharer_verify_code_id = VerifyCode.create!.id
          # 创建抽奖者礼品
          winner_activity_prize = ActivityPrize.create!(activity_info_id: id,
                                                        sharer_id: sharer_id,
                                                        prize_winner_id: winner_id,
                                                        verify_code_id: winner_verify_code_id)

          # 创建分享者礼品
          sharer_activity_prize = ActivityPrize.create!(activity_info_id: id,
                                                        prize_winner_id: sharer_id,
                                                        verify_code_id: sharer_verify_code_id)
        end
        ActivityDrawRecord.create!(activity_info_id: id, user_id: winner_id, sharer_id: sharer_id)

        return winner_activity_prize.present? ? { winner_activity_prize_id: winner_activity_prize.id, sharer_activity_prize_id: sharer_activity_prize.id } : nil
      end
    end
  end

  def draw_live_prize(winner_id)
    if !User.find_by_id(winner_id)
      raise ArgumentError.new('winner not found')
    elsif promotion_activity.status != 'published'
      raise RuntimeError.new('activity not published or closed')
    elsif activity_type != 'live'
      raise RuntimeError.new('wrong method used')
    elsif ActivityDrawRecord.find_by(user_id: winner_id, activity_info_id: id).present?
      raise RepeatedActionError.new('you have already drawed prize')
    else
      ActivityInfo.transaction do
        ActivityInfo.lock
        winner_activity_prize = nil
        if prize_arr.include?(draw_count + 1) # 本次draw_count在中奖数组中
          winner_verify_code_id = VerifyCode.create!.id
          winner_activity_prize = ActivityPrize.create!(activity_info_id: id,
                                                        prize_winner_id: winner_id,
                                                        verify_code_id: winner_verify_code_id)
        end
        # 创建抽奖者礼品
        update!(draw_count: draw_count ? (draw_count + 1) : 1)
        ActivityDrawRecord.create!(activity_info_id: id, user_id: winner_id)

        winner_activity_prize
      end
    end
  end
end

class RepeatedActionError < StandardError
end
