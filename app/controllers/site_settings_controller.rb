class SiteSettingsController < ApplicationController
  before_action :require_superadmin!
  before_action :set_site_setting, only: %i[show edit update reset]

  def index
    @site_settings = SiteSetting.with_attached_logo.order(:key)
  end

  def show; end

  def edit; end

  def update
    if @site_setting.key == "app_logo" && params.dig(:site_setting, :logo).present?
      @site_setting.logo.attach(
        io:           params[:site_setting][:logo],
        filename:     params[:site_setting][:logo].original_filename,
        content_type: "image/svg+xml"
      )
      @site_setting.update!(value: "1")
      redirect_to site_settings_path, notice: "Logo updated."
    elsif @site_setting.update(site_setting_params)
      redirect_to site_settings_path, notice: "Setting updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def reset
    if @site_setting.reset_to_default!
      redirect_to site_settings_path, notice: "\"#{@site_setting.key}\" reset to default."
    else
      redirect_to site_settings_path, alert: "No default defined for \"#{@site_setting.key}\"."
    end
  end

  def update_company
    SiteSetting::COMPANY_KEYS.each do |key|
      short = key.sub("company_", "")
      next unless params.key?(short)

      setting = SiteSetting.find_by!(key: key)
      setting.update!(value: params[short].to_s.strip)
    end

    redirect_to site_settings_path, notice: "Company details updated."
  end

  def update_display
    view = params[:book_list_view].to_s
    view = "table" unless %w[table catalog].include?(view)
    SiteSetting.find_or_create_by!(key: "book_list_view") { |s| s.value = "table" }
               .update!(value: view)

    visibility = params[:book_history_visibility].to_s
    visibility = "staff" unless %w[all staff admin].include?(visibility)
    SiteSetting.find_or_create_by!(key: "book_history_visibility") { |s| s.value = "staff" }
               .update!(value: visibility)

    redirect_to site_settings_path, notice: "Display preferences updated."
  end

  def update_branding
    color_defaults = {
      "primary_color"   => "#4f46e5",
      "secondary_color" => "#111827",
      "tertiary_color"  => "#6366f1"
    }

    %w[app_name primary_color secondary_color tertiary_color].each do |key|
      value = params[key].presence
      next unless value

      setting = SiteSetting.find_or_create_by!(key: key) do |s|
        s.value = color_defaults.fetch(key, value)
      end
      setting.update!(value: value)
    end

    if params[:logo].present?
      logo_setting = SiteSetting.find_or_create_by!(key: "app_logo") { |s| s.value = "1" }
      logo_setting.logo.attach(
        io:           params[:logo],
        filename:     params[:logo].original_filename,
        content_type: "image/svg+xml"
      )
      logo_setting.update!(value: "1")
    end

    if params[:favicon].present?
      favicon_setting = SiteSetting.find_or_create_by!(key: "favicon_icon") { |s| s.value = "1" }
      favicon_setting.logo.attach(
        io:           params[:favicon],
        filename:     params[:favicon].original_filename,
        content_type: "image/svg+xml"
      )
      favicon_setting.update!(value: "1")
    end

    redirect_to site_settings_path, notice: "Branding updated."
  end

  private
    def set_site_setting
      @site_setting = SiteSetting.find(params[:id])
    end

    def site_setting_params
      params.require(:site_setting).permit(:key, :value)
    end
end
