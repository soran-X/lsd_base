class CustomReportTemplatesController < ApplicationController
  before_action -> { authorize!(:index, :custom_report_templates) }, only: %i[index]
  before_action -> { authorize!(:new,   :custom_report_templates) }, only: %i[new create]
  before_action -> { authorize!(:edit,  :custom_report_templates) }, only: %i[edit update]
  before_action -> { authorize!(:destroy, :custom_report_templates) }, only: %i[destroy]
  before_action :set_template, only: %i[show edit update destroy]

  def index
    @templates = CustomReportTemplate.includes(:template_fields, :sections, :reports).order(:name)
  end

  def show
    redirect_to edit_custom_report_template_path(@template)
  end

  def new
    @template = CustomReportTemplate.new
  end

  def create
    @template = CustomReportTemplate.new(template_params)
    @template.created_by = Current.user

    if @template.save
      @template.rebuild_fields!(params.dig(:custom_report_template, :field_keys) || [])
      redirect_to custom_report_templates_path, notice: "Template \"#{@template.name}\" created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @template.update(template_params)
      @template.rebuild_fields!(params.dig(:custom_report_template, :field_keys) || [])
      redirect_to custom_report_templates_path, notice: "Template \"#{@template.name}\" updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @template.reports.exists?
      redirect_to custom_report_templates_path,
        alert: "Cannot delete \"#{@template.name}\" — #{@template.reports.count} report(s) use this template."
    else
      @template.destroy
      redirect_to custom_report_templates_path, notice: "Template deleted."
    end
  end

  private

  def set_template
    @template = CustomReportTemplate.find(params[:id])
  end

  def template_params
    params.expect(
      custom_report_template: [
        :name,
        sections_attributes: [[:id, :name, :position, :_destroy]]
      ]
    )
  end
end
