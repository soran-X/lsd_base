class CustomFieldsController < ApplicationController
  before_action -> { authorize!(:index,   :custom_fields) }, only: %i[index]
  before_action -> { authorize!(:new,     :custom_fields) }, only: %i[new create]
  before_action -> { authorize!(:edit,    :custom_fields) }, only: %i[edit update]
  before_action -> { authorize!(:destroy, :custom_fields) }, only: %i[destroy]
  before_action :set_custom_field, only: %i[edit update destroy]

  def index
    @grouped = CustomField.ordered.group_by(&:group_name)
  end

  def new
    @custom_field = CustomField.new(position: 0)
  end

  def create
    @custom_field = CustomField.new(custom_field_params)
    if @custom_field.save
      redirect_to custom_fields_path, notice: "Custom field \"#{@custom_field.name}\" created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @custom_field.update(custom_field_params)
      redirect_to custom_fields_path, notice: "\"#{@custom_field.name}\" updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @custom_field.name
    @custom_field.destroy!
    redirect_to custom_fields_path, notice: "\"#{name}\" deleted.", status: :see_other
  end

  private

  def set_custom_field
    @custom_field = CustomField.find(params.expect(:id))
  end

  def custom_field_params
    p = params.expect(
      custom_field: [:name, :group_name, :field_type, :position, :required, :active, choices: []]
    )
    # Compact choices — remove blank entries
    p[:choices] = Array(p[:choices]).map(&:strip).reject(&:blank?) if p.key?(:choices)
    p
  end
end
