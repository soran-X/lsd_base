class BooksController < ApplicationController
  before_action :set_book, only: %i[show edit update destroy]

  # GET /books
  def index
    @query        = params[:q].to_s.strip
    @catalog_view = (SiteSetting["book_list_view"] == "catalog")

    catalog_includes = [
      :credited_authors, :translators,
      :genres, :sub_genres, :client_types,
      :primary_scout,
      { book_companies: :company }
    ]
    table_includes = [ :credited_authors, :translators, :primary_scout ]

    if @query.present?
      scope = Book.kept
      scope = scope.where(confidential: false) unless Current.user.hierarchy_level >= 50
      scope = scope.search_globally(@query)
                   .includes(@catalog_view ? catalog_includes : table_includes)
    else
      scope = Book.kept
                  .includes(@catalog_view ? catalog_includes : table_includes)
                  .order(updated_at: :desc)
    end
    @pagy, @books = pagy(scope)
  end

  # GET /books/1
  def show
    @book = Book.kept
                .includes(:credited_authors, :translators,
                           { film_tracking: :film_genres },
                           :primary_scout, :secondary_scout, :genres, :sub_genres,
                           :client_types, :last_updated_by,
                           :reading_materials, :book_memos, :archive_notes,
                           :book_updates,
                           { client_activities: [:company, :contact] },
                           { film_activities:   [:company] },
                           { book_companies:    :company },
                           { book_contacts:     :contact },
                           { readers_reports:   [:reader, :reading_material] })
                .find(params.expect(:id))
    history_min_level = case SiteSetting["book_history_visibility"]
                        when "admin" then 50
                        when "all"   then 0
                        else              25
                        end
    if Current.user.hierarchy_level >= history_min_level
      @recent_updates = AuditLog.where(resource_type: "Book", resource_id: @book.id)
                                 .order(created_at: :desc)
                                 .limit(10)
                                 .includes(:user)
    else
      @recent_updates = []
    end
  end

  # GET /books/new
  def new
    @book = Book.new
    @book.build_film_tracking
  end

  # GET /books/1/edit
  def edit
    @book.film_tracking || @book.build_film_tracking
  end

  # POST /books
  def create
    @book = Book.new(book_params)
    @book.last_updated_by = Current.user

    respond_to do |format|
      if @book.save
        assign_book_authors(@book)
        assign_book_companies_and_contacts(@book)
        AuditLog.record(user: Current.user, action: "create", resource: @book,
                        metadata: { title: @book.title }, request: request)
        format.html { redirect_to @book, notice: "Book was successfully created." }
        format.json { render :show, status: :created, location: @book }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /books/1
  def update
    @book.last_updated_by = Current.user

    # Snapshot author/translator IDs before the save so we can diff them after
    author_ids_before     = @book.credited_authors.order(:id).pluck(:id)
    translator_ids_before = @book.translators.order(:id).pluck(:id)

    respond_to do |format|
      if @book.update(book_params)
        assign_book_authors(@book)
        assign_book_companies_and_contacts(@book)

        # ── Scalar field changes ────────────────────────────────────────────
        # Exclude rich-text fields from previous_changes — Trix re-normalises
        # HTML on every submit, so they always appear as changed.  We re-add
        # them below only if the stripped text content actually differs.
        changes = @book.previous_changes.except(
          "updated_at", "synopsis_plain", "last_updated_by_id", "created_at",
          "synopsis", "notes", "readers_report", "material_to_read",
          "rights_sold", "log_line", "pub_info", "material"
        )

        # ── Rich-text fields: only log when text content changed ────────────
        strip_html = ->(h) { h.to_s.gsub(/<[^>]+>/, " ").gsub(/\s+/, " ").strip }

        # synopsis_plain is recomputed in before_save; compare it to avoid
        # logging cosmetic HTML re-normalisations as real changes.
        if @book.previous_changes.key?("synopsis_plain")
          before_plain, after_plain = @book.previous_changes["synopsis_plain"]
          # If synopsis_plain was nil (never computed), derive the effective before-value
          # from the pre-update synopsis HTML so we don't log a false change.
          if before_plain.nil?
            old_html = @book.previous_changes.dig("synopsis", 0)
            before_plain = old_html ?
              old_html.gsub(/<[^>]+>/, " ").gsub(/&[a-zA-Z]+;|&#\d+;/, " ").gsub(/\s+/, " ").strip :
              after_plain
          end
          changes["synopsis"] = @book.previous_changes["synopsis"] if before_plain != after_plain
        end

        %w[readers_report].each do |field|
          next unless @book.previous_changes.key?(field)
          before_t = strip_html.call(@book.previous_changes[field][0])
          after_t  = strip_html.call(@book.previous_changes[field][1])
          changes[field] = @book.previous_changes[field] if before_t != after_t
        end

        # ── Author / translator changes ─────────────────────────────────────
        author_ids_after     = @book.credited_authors.reload.order(:id).pluck(:id)
        translator_ids_after = @book.translators.reload.order(:id).pluck(:id)

        name_list = ->(ids) {
          ids.empty? ? "—" : Author.where(id: ids).order(:last_name, :first_name)
                                   .map(&:display_name).join(", ")
        }

        if author_ids_before != author_ids_after
          changes["authors"] = [name_list.call(author_ids_before),
                                 name_list.call(author_ids_after)]
        end

        if translator_ids_before != translator_ids_after
          changes["translators"] = [name_list.call(translator_ids_before),
                                     name_list.call(translator_ids_after)]
        end

        AuditLog.record(user: Current.user, action: "update", resource: @book,
                        metadata: { changes: changes }, request: request) if changes.any?
        format.html { redirect_to @book, notice: "Book was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @book }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /books/1
  def destroy
    title = @book.title
    @book.discard!
    AuditLog.record(user: Current.user, action: "discard", resource: @book,
                    metadata: { title: title }, request: request)

    respond_to do |format|
      format.html { redirect_to books_path, notice: "Book was successfully removed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_book
    @book = Book.kept.find(params.expect(:id))
  end

  def book_params
    p = params.expect(
      book: [
        :title, :old_title, :subtitle, :synopsis,
        :publication_year, :publication_season,
        :delivery_date, :followup_date,
        :confidential, :status,
        :lead_title, :tracking_material,
        :readers_report, :material_to_read,
        :confidential_report,
        :primary_scout_id, :secondary_scout_id,
        :rights_sold, :log_line, :pub_info, :material,
        :confidential_material, :update_tagline,
        book_updates_attributes: [
          [:id, :content, :_destroy]
        ],
        genre_ids: [], sub_genre_ids: [], client_type_ids: [],
        film_activities_attributes: [
          [:id, :date, :client, :company_id, :notes, :_destroy]
        ],
        film_tracking_attributes: [
          :id, :film_synopsis, :film_option, :film_option_date,
          :readers_thoughts, :category, :comments, :material,
          :off, :pub_buzz, :_destroy
        ],
        reading_materials_attributes: [
          [:id, :material, :reader, :number_of_pages, :date, :_destroy]
        ],
        client_activities_attributes: [
          [:id, :date, :activity_type, :company_id, :contact_id, :content, :_destroy]
        ],
        book_memos_attributes: [
          [:id, :note, :date, :_destroy]
        ],
        archive_notes_attributes: [
          [:id, :note, :date, :_destroy]
        ],
        readers_reports_attributes: [
          [:id, :report_date, :reader_id, :sent_to,
           :comments, :film_commentary, :synopsis,
           :publishing_recommended, :publishing_recommendation,
           :film_recommended, :reading_material_id, :_destroy]
        ]
      ]
    )
    p[:genre_ids]       = Array(p[:genre_ids]).compact_blank.map(&:to_i)       if p.key?(:genre_ids)
    p[:sub_genre_ids]   = Array(p[:sub_genre_ids]).compact_blank.map(&:to_i)   if p.key?(:sub_genre_ids)
    p[:client_type_ids] = Array(p[:client_type_ids]).compact_blank.map(&:to_i) if p.key?(:client_type_ids)
    p
  end

  # Replaces author/translator assignments from the combobox hidden inputs.
  # Params expected:
  #   book[author_ids][]     → array of author IDs with role "author"
  #   book[translator_ids][] → array of author IDs with role "translator"
  def assign_book_authors(book)
    assign_role(book, :author,     Array(params.dig(:book, :author_ids)).compact_blank.map(&:to_i))
    assign_role(book, :translator, Array(params.dig(:book, :translator_ids)).compact_blank.map(&:to_i))
  end

  def assign_role(book, role, ids)
    existing = book.book_authors.where(role: role)
    existing.where.not(author_id: ids).destroy_all
    existing_ids = existing.pluck(:author_id)

    (ids - existing_ids).each do |author_id|
      book.book_authors.create!(author_id: author_id, role: role)
    end
  end

  # ── Company & Contact assignment ──────────────────────────────────────────

  def assign_book_companies_and_contacts(book)
    # Single-select companies
    assign_single_book_company(book, :publisher, params.dig(:book, :publisher_company_id))
    assign_single_book_company(book, :editor,    params.dig(:book, :editor_company_id))

    # Multi-select companies
    assign_multi_book_company(book, :agency,
      Array(params.dig(:book, :agency_company_ids)).compact_blank.map(&:to_i))
    assign_multi_book_company(book, :film_agency,
      Array(params.dig(:book, :film_agency_company_ids)).compact_blank.map(&:to_i))

    # Multi-select contacts
    assign_multi_book_contact(book, :agent,
      Array(params.dig(:book, :agent_contact_ids)).compact_blank.map(&:to_i))
    assign_multi_book_contact(book, :film_agent,
      Array(params.dig(:book, :film_agent_contact_ids)).compact_blank.map(&:to_i))

    # Rights
    assign_single_book_company(book, :rights_holder, params.dig(:book, :rights_holder_company_id))
    assign_multi_book_company(book, :secondary_rights_holder,
      Array(params.dig(:book, :secondary_rights_holder_company_ids)).compact_blank.map(&:to_i))

    # Film genres (via film_tracking)
    if book.film_tracking
      film_genre_ids = Array(params.dig(:book, :film_genre_ids)).compact_blank.map(&:to_i)
      ft = book.film_tracking
      ft.film_tracking_genres.where.not(film_genre_id: film_genre_ids).destroy_all
      existing_ids = ft.film_tracking_genres.pluck(:film_genre_id)
      (film_genre_ids - existing_ids).each { |gid| ft.film_tracking_genres.create!(film_genre_id: gid) }
    end
  end

  def assign_single_book_company(book, role, company_id)
    raw = company_id.to_s.strip
    existing = book.book_companies.find_by(role: BookCompany.roles[role])
    if raw.blank?
      existing&.destroy
    else
      id = raw.to_i
      if existing
        existing.update!(company_id: id) unless existing.company_id == id
      else
        book.book_companies.create!(company_id: id, role: role)
      end
    end
  end

  def assign_multi_book_company(book, role, ids)
    existing = book.book_companies.where(role: BookCompany.roles[role])
    existing.where.not(company_id: ids).destroy_all
    existing_ids = existing.pluck(:company_id)
    (ids - existing_ids).each { |cid| book.book_companies.create!(company_id: cid, role: role) }
  end

  def assign_multi_book_contact(book, role, ids)
    existing = book.book_contacts.where(role: BookContact.roles[role])
    existing.where.not(contact_id: ids).destroy_all
    existing_ids = existing.pluck(:contact_id)
    (ids - existing_ids).each { |cid| book.book_contacts.create!(contact_id: cid, role: role) }
  end
end
