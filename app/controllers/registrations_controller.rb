class RegistrationsController < ApplicationController
  skip_before_action :authenticate
  skip_before_action :require_approved!
  before_action :check_signup_enabled, only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.role = Role.find_by(name: "Client")

    if @user.save
      session_record = @user.sessions.create!
      cookies.signed.permanent[:session_token] = { value: session_record.id, httponly: true }

      send_email_verification
      redirect_to root_path, notice: "Welcome! Your account is pending approval."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.permit(:first_name, :last_name, :email, :password, :password_confirmation)
    end

    def send_email_verification
      UserMailer.with(user: @user).email_verification.deliver_later
    end
end
