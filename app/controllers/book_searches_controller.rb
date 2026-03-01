class BookSearchesController < ApplicationController
  before_action :set_lookup_data, only: %i[new show]

  def index
    @book_searches = Current.user.book_searches.order(created_at: :desc).limit(50)
  end

  def new
    @book_search = BookSearch.new
  end

  def create
    @book_search = Current.user.book_searches.build(params: search_q_params.to_h)
    if @book_search.save
      redirect_to @book_search
    else
      set_lookup_data
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @book_search = Current.user.book_searches.find(params[:id])
    @results = BookSearchQuery.new(@book_search.params, current_user: Current.user)
                              .call
                              .includes(:credited_authors, :primary_scout, :genres, :sub_genres)
                              .order(updated_at: :desc)
    load_saved_associations
  end

  def destroy
    Current.user.book_searches.find(params[:id]).destroy
    redirect_to book_searches_path, notice: "Search deleted."
  end

  private

  def set_lookup_data
    @genres       = Genre.ordered
    @sub_genres   = SubGenre.ordered
    @client_types = ClientType.ordered
  end

  def search_q_params
    params.fetch(:q, {}).permit(
      :keyword, :to_read, :lead_title, :tracking_material,
      :rights_sold_text,
      :updated_after, :updated_before,
      :entered_after, :entered_before,
      :published_after, :published_before,
      :delivered_after, :delivered_before,
      :followup_after, :followup_before,
      :activity_after, :activity_before,
      :read_after, :read_before,
      status: [], genre_ids: [], sub_genre_ids: [], client_type_ids: [],
      author_ids: [], scout_ids: [], reader_ids: [],
      agency_company_ids: [], film_agency_company_ids: [],
      publisher_company_ids: [], editor_company_ids: [],
      rights_holder_company_ids: [],
      agent_contact_ids: [], film_agent_contact_ids: [],
      client_activity_company_ids: [], client_activity_contact_ids: [],
      activity_types: []
    )
  end

  def load_saved_associations
    p = @book_search.params
    @saved_authors           = Author.where(id: p["author_ids"])
    @saved_scouts            = User.where(id: p["scout_ids"])
    @saved_readers           = User.where(id: p["reader_ids"])
    @saved_agencies          = Company.where(id: p["agency_company_ids"])
    @saved_film_agencies     = Company.where(id: p["film_agency_company_ids"])
    @saved_publishers        = Company.where(id: p["publisher_company_ids"])
    @saved_editors           = Company.where(id: p["editor_company_ids"])
    @saved_rights_holders    = Company.where(id: p["rights_holder_company_ids"])
    @saved_agents            = Contact.where(id: p["agent_contact_ids"])
    @saved_film_agents       = Contact.where(id: p["film_agent_contact_ids"])
    @saved_ca_companies      = Company.where(id: p["client_activity_company_ids"])
    @saved_ca_contacts       = Contact.where(id: p["client_activity_contact_ids"])
  end
end
