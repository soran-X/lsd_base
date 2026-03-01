class UsersController < ApplicationController
  before_action :require_admin!, except: [:search]
  before_action :set_user, only: %i[show edit update destroy]
  before_action -> { enforce_hierarchy!(@user) }, only: %i[show edit update destroy]

  def search
    q = params[:q].to_s.strip
    users = q.length >= 1 ? User.kept.search_by_name(q).limit(10) : User.kept.order(:last_name, :first_name).limit(10)
    render json: users.map { |u| { id: u.id, label: u.display_name } }
  end

  def index
    @users = User.includes(:role).order(:email)
  end

  def show; end

  def new
    @user = User.new
    @roles = Role.assignable_by(Current.user.role).ordered
  end

  def create
    target_role = Role.find_by(id: new_user_params[:role_id])
    if target_role && !Current.user.can_assign_role?(target_role)
      redirect_to users_path, alert: "You cannot assign a role with higher hierarchy than your own."
      return
    end

    @user = User.new(new_user_params)
    @user.approved = true
    @user.password = SecureRandom.base58(24)

    if @user.save
      UserMailer.with(user: @user).invitation.deliver_later
      redirect_to users_path, notice: "Invitation sent to #{@user.email}."
    else
      @roles = Role.assignable_by(Current.user.role).ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @roles = Role.assignable_by(Current.user.role).ordered
  end

  def update
    target_role = Role.find_by(id: user_params[:role_id])
    if target_role && !Current.user.can_assign_role?(target_role)
      redirect_to users_path, alert: "You cannot assign a role with higher hierarchy than your own."
      return
    end

    if @user.update(user_params)
      redirect_to users_path, notice: "User updated successfully."
    else
      @roles = Role.assignable_by(Current.user.role).ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path, notice: "User removed."
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name, :role_id, :approved)
    end

    def new_user_params
      params.require(:user).permit(:first_name, :last_name, :email, :role_id)
    end
end
