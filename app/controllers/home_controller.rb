class HomeController < ApplicationController
  skip_before_action :require_approved!, only: :pending_approval

  def index
    redirect_to dashboard_path
  end

  def dashboard
  end

  def pending_approval
  end
end
