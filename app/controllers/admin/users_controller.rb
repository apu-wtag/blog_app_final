class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :destroy, :restore, :update_role]
  def index
    @users = User.order(:name)
    if params[:query].present?
      @users = @users.where("name ILIKE ? or email ILIKE ? or user_name ILIKE ?", "%#{params[:query]}%", "%#{params[:query]}%", "%#{params[:query]}%")
    end
    @pagy, @users = pagy(@users, items: 10)
  end
  def destroy
    if @user == current_user
      redirect_to admin_users_path, notice: "You cannot delete your own account."
    else
      @user.discard
      redirect_to admin_users_path, notice: "User was successfully deleted."
    end
  end
  def restore
    if @user.undiscard
      redirect_to admin_users_path, notice: "User #{@user.name} was successfully restored."
    else
      redirect_to admin_users_path, alert: "Failed to restore user."
    end
  end

  def update_role
    if @user.update(role_params)
      redirect_to admin_users_path, notice: "#{@user.name}'s role was updated to #{@user.role}."
    else
      redirect_to admin_users_path, alert: "Failed to update role."
    end
  end
  private

  def set_user
    @user = User.friendly.find(params[:id])
  end

  def role_params
    params.require(:user).permit(:role)
  end
end
