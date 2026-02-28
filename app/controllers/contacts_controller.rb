class ContactsController < ApplicationController
  before_action :set_contact, only: %i[show edit update destroy]

  def index
    @query = params[:q].to_s.strip
    @contacts = if @query.present?
      Contact.kept.search_by_name(@query).includes(:company)
    else
      Contact.kept.includes(:company).ordered
    end
  end

  def show
    @contact = Contact.kept.includes(:company, books: :credited_authors)
                      .find(params.expect(:id))
  end

  def new
    @contact = Contact.new
    @contact.company_id = params[:company_id] if params[:company_id]
  end

  def create
    @contact = Contact.new(contact_params)
    if @contact.save
      redirect_to @contact, notice: "Contact \"#{@contact.display_name}\" created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @contact.update(contact_params)
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
      :first_name, :last_name, :title, :email, :phone, :company_id, :notes
    ])
  end
end
