class ApprovalsController < ApplicationController
  before_action :require_admin!
  before_action :set_user

  def update
    target_role = Role.find_by(id: params[:role_id])

    if target_role && !Current.user.can_assign_role?(target_role)
      redirect_to users_path, alert: "You cannot assign a role with higher hierarchy than your own."
      return
    end

    @user.assign_attributes(approved: true)
    @user.role = target_role if target_role

    if @user.save
      redirect_to users_path, notice: "#{@user.email} has been approved."
    else
      redirect_to users_path, alert: "Could not approve user: #{@user.errors.full_messages.to_sentence}"
    end
  end

  private

    def set_user
      @user = User.find(params[:user_id])
      enforce_hierarchy!(@user)
    end
end
