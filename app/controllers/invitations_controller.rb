class InvitationsController < ApplicationController
  skip_before_action :authenticate
  skip_before_action :require_approved!

  def show
    @user = find_user_by_token
    redirect_to sign_in_path, alert: "This invitation link is invalid or has expired." unless @user
  end

  def update
    @user = find_user_by_token
    unless @user
      redirect_to sign_in_path, alert: "This invitation link is invalid or has expired."
      return
    end

    if @user.update(password_params.merge(verified: true))
      session_record = @user.sessions.create!
      cookies.signed.permanent[:session_token] = { value: session_record.id, httponly: true }
      redirect_to root_path, notice: "Welcome! Your account is ready."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
    def find_user_by_token
      User.find_by_token_for(:invitation, params[:token])
    end

    def password_params
      params.require(:user).permit(:password, :password_confirmation)
    end
end
