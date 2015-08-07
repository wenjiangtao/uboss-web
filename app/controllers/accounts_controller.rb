class AccountsController < ApplicationController
  before_action :authenticate_user!

  def show
    @orders = append_default_filter account_orders, page_size: 20
  end

  def orders
    @orders = append_default_filter account_orders, page_size: 20
    render partial: 'accounts/order', collection: @orders
  end

  def edit
  end

  def update
    if account_params[:login].present? and account_params[:code].present?
     MobileAuthCode.auth_code(account_params[:login], account_params[:code])
     current_user.update(login: account_params[:login])
     flash[:notice] = '绑定成功'
     redirect_to settings_account_path
     return
    elsif current_user.update(account_params)
      flash[:notice] = '修改成功'
      redirect_to settings_account_path
    else
      render :edit
    end
  end

  def settings # 个人信息展示
  end

  def update_password_page # 修改密码页面
  end

  def new_agent_binding # 商家绑定创客
  end

  def edit_mobile_page
    if current_user.login.present?
      flash[:info] = "你已经有帐号了"
      redirect_to settings_account_path
    end
  end

  def update_password
    user_params = params.require(:user).permit(:password, :password_confirmation, :current_password,:code)
    update_with_password_params = params.require(:user).permit(:password, :password_confirmation, :current_password)
    if  current_user.need_reset_password
      if MobileAuthCode.auth_code(current_user.login, user_params[:code])
        current_user.update(password: user_params[:password], password_confirmation: user_params[:password_confirmation],need_reset_password:false)
        sign_in current_user, :bypass => true
        redirect_to settings_account_path, notice: '修改密码成功'
      else
        render :update_password_page
        return
      end
    elsif current_user.update_with_password(update_with_password_params)
      sign_in current_user, :bypass => true
      redirect_to settings_account_path, notice: '修改密码成功'
    else
      render :update_password_page
    end
  end

  def set_password
  end

  def reset_password
    current_user.update(need_reset_password: true)
    redirect_to update_password_page_account_path
  end

  def agent_invite_seller
    agent_action
    @histroys = AgentInviteSellerHistroy.where(agent_id: current_user.id)
    @bind = User.where(agent_id: current_user, authenticated: 1).count
  end

  def edit_seller_note
    agent_action
    @histroy = AgentInviteSellerHistroy.find(params[:id])
  end

  def update_histroy_note
    agent_action
    note = params[:histroy][:note] rescue nil
    histroy = AgentInviteSellerHistroy.find_by(id: params[:id])
    if histroy.present? and note.present? and histroy.agent_id == current_user.id
      histroy.update(note: note)
      flash[:success] = "修改成功"
    else
      flash[:error] = "修改失败#{histroy.errors.messages}."
    end
    redirect_to action: :agent_invite_seller
  end

  def send_message
    agent_action
    mobile = params[:send_message][:mobile] rescue nil
    if mobile.present? and mobile =~ /\A(\s*)(?:\(?[0\+]?\d{1,3}\)?)[\s-]?(?:0|\d{1,4})[\s-]?(?:(?:13\d{9})|(?:\d{7,8}))(\s*)\Z|\A[569][0-9]{7}\Z/
      sms = send_sms(mobile, current_user.agent_code)
      if sms == 'OK'
        aish = AgentInviteSellerHistroy.find_by(mobile: mobile)
        if !aish.present?
          AgentInviteSellerHistroy.create(agent_id: current_user.id, mobile: mobile)
        end
      else
        flash[:error] = "短信发送失败,#{sms}."
      end
    else
      flash[:error] = "手机格式不正确"
    end
    redirect_to action: :agent_invite_seller
  end

  def send_sms(mobile,msg,tpl_id=923651) # 发送短信
    agent_action
    return {'msg'=> 'error',"detail"=>"电话号码不能为空"} if mobile.blank?
    return {'msg'=> 'error',"detail"=>"内容不能为空"} if msg.blank?
    begin
      sms = ChinaSMS.to(mobile, {code:msg}, tpl_id: tpl_id)
      return "OK" if sms['msg'] == "OK"
      return sms
    rescue Exception => e
      return e.message
    end
  end

  def binding_agent # 商家绑定创客
    if current_user.authenticated?
      flash[:notice] = "您已经是认证商家，不能更换绑定"
    else
      valid_code
      if @errors.present?
        flash[:error] = @errors.join("\n")
        redirect_to action: :new_agent_binding, agent_code: params[:agent_code]
        return
      else
        agent = User.find_by(agent_code: params[:agent_code])
        current_user.agent_id = agent.id
        current_user.admin = true
        current_user.save
        aish = AgentInviteSellerHistroy.find_by(mobile: current_user.login)
        if aish.present?
          aish.update(status: 1)
        end
        flash[:success] = "绑定成功,#{agent.identify}成为您的创客。"
      end
    end
    redirect_to action: :new_agent_binding
  end

  private
  def account_orders
    current_user.orders.includes(order_items: { product: :asset_img })
  end

  def account_params
    if current_user.login.present?
      params.require(:user).permit(:mobile, :nickname, :login)
    else
      params.require(:user).permit(:nickname)
    end
  end

  def valid_code
    @errors = []
    hash = {
      '验证码错误或已过期。': MobileAuthCode.auth_code(account_params[:mobile], account_params[:mobile_auth_code]),
      '创客邀请码错误。': User.find_by(agent_code: params[:agent_code]),
    }
    hash.each do |k, v|
      @errors << k unless v.present?
    end
  end

  def agent_action
    if !current_user.agent?
      flash[:error] = "您还不是创客."
      redirect_to action: :settings
      return
    end
  end
end
