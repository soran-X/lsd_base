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
      @books = scope.search_globally(@query)
                    .includes(@catalog_view ? catalog_includes : table_includes)
    else
      @books = Book.kept
                   .includes(@catalog_view ? catalog_includes : table_includes)
                   .order(updated_at: :desc)
    end
  end

  # GET /books/1
  def show
    @book = Book.kept
                .includes(:credited_authors, :translators, :film_tracking,
                           :primary_scout, :secondary_scout, :genres, :sub_genres,
                           :client_types, :last_updated_by,
                           :reading_materials, :book_memos, :archive_notes,
                           { client_activities: [:company, :contact] })
                .find(params.expect(:id))
    history_min_level = case SiteSetting["book_history_visibility"]
                        when "admin" then 50
                        when "all"   then 0
                        else              25
                        end
    if Current.user.hierarchy_level >= history_min_level
      @recent_updates = AuditLog.where(resource_type: "Book", resource_id: @book.id)
                                 .order(created_at: :desc)
                                 .limit(3)
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

        # ── Scalar field changes ────────────────────────────────────────────
        # Exclude rich-text fields from previous_changes — Trix re-normalises
        # HTML on every submit, so they always appear as changed.  We re-add
        # them below only if the stripped text content actually differs.
        changes = @book.previous_changes.except(
          "updated_at", "synopsis_plain", "last_updated_by_id", "created_at",
          "synopsis", "notes", "readers_report", "material_to_read"
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
        :primary_scout_id, :secondary_scout_id,
        genre_ids: [], sub_genre_ids: [], client_type_ids: [],
        film_tracking_attributes: [
          :id, :film_synopsis, :film_option,
          :readers_thoughts, :category, :_destroy
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
end
