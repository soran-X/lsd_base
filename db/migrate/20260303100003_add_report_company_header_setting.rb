class AddReportCompanyHeaderSetting < ActiveRecord::Migration[8.1]
  def up
    SiteSetting.find_or_create_by!(key: "report_company_header") { |s| s.value = "true" }
  end

  def down
    SiteSetting.where(key: "report_company_header").destroy_all
  end
end
