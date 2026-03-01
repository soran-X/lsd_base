class ContactsController < ApplicationController
  before_action :set_contact, only: %i[show edit update destroy]

  def index
    @query = params[:q].to_s.strip
    @contacts = if @query.present?
      Contact.kept.search_by_name(@query).includes(:companies)
    else
      Contact.kept.includes(:companies).ordered
    end
  end

  # GET /contacts/search.json?q=Smith
  def search
    q        = params[:q].to_s.strip
    contacts = Contact.kept.order(:last_name, :first_name)
    contacts = contacts.search_by_name(q) if q.present?
    render json: contacts.limit(15).map { |c| { id: c.id, label: c.display_name } }
  end

  def show
    @contact = Contact.kept.includes(:companies, books: :credited_authors)
                      .find(params.expect(:id))
  end

  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)
    if @contact.save
      assign_contact_companies(@contact)
      redirect_to @contact, notice: "Contact \"#{@contact.display_name}\" created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @contact.update(contact_params)
      assign_contact_companies(@contact)
      redirect_to @contact, notice: "Contact updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @contact.display_name
    @contact.discard!
    redirect_to contacts_path, notice: "\"#{name}\" removed.", status: :see_other
  end

  private

  def set_contact
    @contact = Contact.kept.find(params.expect(:id))
  end

  def contact_params
    params.expect(contact: [
      :first_name, :last_name, :title, :email, :phone, :notes,
      :assistant_name, :tracked_by_id,
      :address_line_1, :address_line_2, :city, :state, :country, :zip,
      :direct_number, :mobile_number, :home_number, :fax_number
    ])
  end

  def assign_contact_companies(contact)
    ids = Array(params.dig(:contact, :company_ids)).compact_blank.map(&:to_i)
    existing = contact.contact_companies
    existing.where.not(company_id: ids).destroy_all
    existing_ids = existing.reload.pluck(:company_id)
    (ids - existing_ids).each { |cid| contact.contact_companies.create!(company_id: cid) }
  end
end
