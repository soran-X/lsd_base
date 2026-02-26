class ApplicationController < ActionController::Base
  include Authorizable

  allow_browser versions: :modern

  before_action :set_current_request_details
  before_action :authenticate
  before_action :require_approved!

  private

    def authenticate
      if session_record = Session.find_by_id(cookies.signed[:session_token])
        Current.session = session_record
      else
        redirect_to sign_in_path
      end
    end

    def require_approved!
      return unless Current.user
      unless Current.user.approved?
        sign_out_and_redirect(pending_approval_path)
      end
    end

    def check_signup_enabled
      unless SiteSetting.allow_public_signup?
        redirect_to sign_in_path, alert: "Public registration is currently disabled."
      end
    end

    def require_admin!
      unless Current.user&.admin?
        redirect_to root_path, alert: "Not authorized."
      end
    end

    def require_superadmin!
      unless Current.user&.superadmin?
        redirect_to root_path, alert: "Not authorized."
      end
    end

    # Enforce hierarchy: actor cannot manage targets with higher level
    def enforce_hierarchy!(target_user)
      unless Current.user.can_manage?(target_user)
        redirect_to root_path, alert: "You cannot manage users with a higher role level."
      end
    end

    def sign_out_and_redirect(path)
      cookies.delete(:session_token)
      redirect_to path, alert: "Your account is pending approval."
    end

    def set_current_request_details
      Current.user_agent = request.user_agent
      Current.ip_address = request.ip
    end
end
