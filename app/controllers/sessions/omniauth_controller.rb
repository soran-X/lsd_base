class Sessions::OmniauthController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate
  skip_before_action :require_approved!

  def create
    @user = User.from_omniauth(omniauth)
    @user.role ||= Role.find_by(name: "Client")

    if @user.save
      session_record = @user.sessions.create!
      cookies.signed.permanent[:session_token] = { value: session_record.id, httponly: true }

      if @user.approved?
        redirect_to root_path, notice: "Signed in with #{omniauth.provider.capitalize} successfully."
      else
        cookies.delete(:session_token)
        session_record.destroy
        redirect_to sign_in_path, alert: "Your account is pending approval. Please wait for an admin to approve you."
      end
    else
      redirect_to sign_in_path, alert: "Authentication failed: #{@user.errors.full_messages.to_sentence}"
    end
  end

  def failure
    redirect_to sign_in_path, alert: params[:message]
  end

  private
    def omniauth
      request.env["omniauth.auth"]
    end
end
