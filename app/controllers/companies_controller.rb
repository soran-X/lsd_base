class CompaniesController < ApplicationController
  before_action :set_company, only: %i[show edit update destroy]

  def index
    @query = params[:q].to_s.strip
    @companies = if @query.present?
      Company.kept.search_by_name(@query).includes(:company_type)
    else
      Company.kept.includes(:company_type).ordered
    end
  end

  def show
    @company = Company.kept
                      .includes(:company_type, contacts: [],
                                books: :credited_authors,
                                company_subagents: [:territory, :subagent_company])
                      .find(params.expect(:id))
  end

  def search
    q         = params[:q].to_s.strip
    companies = Company.kept.order(:name)
    companies = companies.search_by_name(q) if q.present?
    render json: companies.limit(15).map { |c| { id: c.id, label: c.name } }
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params)
    if @company.save
      redirect_to @company, notice: "Company \"#{@company.name}\" created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @company.update(company_params)
      redirect_to @company, notice: "Company updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @company.name
    @company.discard!
    redirect_to companies_path, notice: "\"#{name}\" removed.", status: :see_other
  end

  private

  def set_company
    @company = Company.kept.find(params.expect(:id))
  end

  def company_params
    params.expect(company: [
      :name, :company_type_id, :website,
      :address_line_1, :address_line_2, :city, :state, :postal_code, :country,
      :phone, :fax, :notes,
      :nest_subagents, :viewable_by_clients,
      company_subagents_attributes: [
        [:id, :subagent_company_id, :territory_id, :_destroy]
      ]
    ])
  end
end
