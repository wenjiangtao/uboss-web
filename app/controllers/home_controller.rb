class HomeController < ApplicationController

  detect_device only: [:index, :service_centre_consumer, :service_centre_agent, :service_centre_tutorial]

  layout :detect_layout, only: [:index, :service_centre_tutorial, :service_centre_agent, :service_centre_consumer, :lady, :maca, :snacks,:city]

  def index
    if !desktop_request?
      redirect_to stores_path
    end
  end

  def service_centre_consumer
  end

  def service_centre_agent
  end

  def service_centre_tutorial
  end

  def maker_qrcode
    @user = User.find(params.fetch(:uid))
    render layout: false
  end

  def about_us
    render layout: 'mobile'
  end

  def qrcode
    qrcode = QrcodeService.new(params.fetch(:text), params[:logo])
    if qrcode.url.present?
      redirect_to qrcode.url
    else
      head(422)
    end
  end

  def hongbao_game
    render layout: nil
  end

  def store_qrcode_img
    @promotion_activity = PromotionActivity.find_by(user_id: params[:sid], status: 1)
    cookies['activity_store_type'] = params[:type]
    if @promotion_activity.present?
      redirect_to promotion_activity_path(@promotion_activity, type: 'live')
    else
      if current_user && ['ordinary', 'service'].include?(params[:type]) && (privilege_card = PrivilegeCard.find_or_active_card(current_user.id, params[:sid]))
        @qrcode_img_url = params[:type] == 'ordinary' ? privilege_card.ordinary_store_qrcode_img_url : privilege_card.service_store_qrcode_img_url
      end
      render layout: nil
    end
  end

  def generate_privilege_card
    user = User.find_or_create_guest(params[:mobile])
    if !['ordinary', 'service'].include?(params[:type])
      render json: {status: 400, message: '类型错误'}
    elsif !params[:sid]
      render json: {status: 400, message: '请提供sid'}
    elsif privilege_card = PrivilegeCard.find_or_active_card(user.id, params[:sid])
      @qrcode_img_url = params[:type] == 'ordinary' ? privilege_card.ordinary_store_qrcode_img_url : privilege_card.service_store_qrcode_img_url
      render json: {status: 200, message: @qrcode_img_url}
    else
      render json: {status:400, message: '创建友情卡失败'}
    end
  end

  private

  def detect_layout
    if not desktop_request?
      'mobile'
    else
      'desktop'
    end
  end

end
