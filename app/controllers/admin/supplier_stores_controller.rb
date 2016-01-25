class Admin::SupplierStoresController < AdminController

  before_action :set_supplier_store, except: :create
  authorize_resource

  def new
  end

  def create
    @supplier_store = current_user.build_supplier_store
    @supplier_store.build_supplier_store_info
    @supplier_store.attributes = supplier_store_params
    if @supplier_store.save and current_user.user_roles.create(name: 'supplier', display_name: '供应商')
      flash[:success] = '恭喜，创建供货店铺成功！'
      redirect_to edit_info_admin_supplier_stores_path
    else
      flash[:error] = '创建失败！'
      redirect_to :back
    end
  end

  def edit_info
  end

  def update_info
    if @supplier_store.update_attributes(supplier_store_params)
      flash[:success] = '完善客服信息成功！'
      redirect_to admin_agencies_path
    else
      flash[:error] = '完善客服信息失败'
      redirect_to :back
    end
  end

  def destroy
    if current_user.user_roles.find_by(name: 'supplier', display_name: '供应商').destroy and @supplier_store.destroy
      flash[:success] = '成功解除供应商身份！'
    else
      flash[:error] = '解除供应商身份失败！'
    end
    redirect_to :back
  end

  private

  def supplier_store_params
    params.require(:supplier_store).permit(:store_name, :province, :city, :area, :guess_province, :guess_city, :phone_number, :wechat_id)
  end

  def set_supplier_store
    @supplier_store = current_user.supplier_store || SupplierStore.new
  end

end
