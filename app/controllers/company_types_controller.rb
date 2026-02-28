class CompanyTypesController < ApplicationController
  before_action :require_admin
  before_action :set_company_type, only: %i[edit update destroy]

  def index
    @company_types = CompanyType.ordered
  end

  def new
    @company_type = CompanyType.new
  end

  def create
    @company_type = CompanyType.new(company_type_params)
    if @company_type.save
      redirect_to company_types_path, notice: "\"#{@company_type.name}\" created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @company_type.update(company_type_params)
      redirect_to company_types_path, notice: "\"#{@company_type.name}\" updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @company_type.name
    @company_type.destroy!
    redirect_to company_types_path, notice: "\"#{name}\" deleted.", status: :see_other
  end

  private

  def set_company_type
    @company_type = CompanyType.find(params.expect(:id))
  end

  def company_type_params
    params.expect(company_type: [:name])
  end

  def require_admin
    redirect_to root_path, alert: "Not authorized." unless Current.user.hierarchy_level >= 50
  end
end
