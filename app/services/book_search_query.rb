class BookSearchQuery
  def initialize(params, current_user:)
    @params = params.with_indifferent_access
    @user   = current_user
  end

  def call
    scope = Book.kept

    # Confidential filter
    scope = scope.where(confidential: false) unless @user.hierarchy_level >= 50

    scope = apply_keyword(scope)
    scope = apply_status(scope)
    scope = apply_booleans(scope)
    scope = apply_genres(scope)
    scope = apply_sub_genres(scope)
    scope = apply_client_types(scope)
    scope = apply_authors(scope)
    scope = apply_companies(scope)
    scope = apply_contacts(scope)
    scope = apply_client_activities(scope)
    scope = apply_scouts(scope)
    scope = apply_readers(scope)
    scope = apply_rights_sold_text(scope)
    scope = apply_date_ranges(scope)

    scope.distinct
  end

  private

  # ── Keyword ────────────────────────────────────────────────────────────────

  def apply_keyword(scope)
    raw = @params[:keyword].to_s.strip
    return scope if raw.blank?

    remainder = raw.dup
    t = Book.arel_table

    plain_cols = %i[title old_title synopsis_plain material_plain pub_info_plain
                    log_line_plain notes_plain rights_sold_plain]

    build_or_cond = ->(term) {
      sanitized = term.gsub("%", "").gsub("_", "")
      plain_cols.map { |c| t[c].matches("%#{sanitized}%") }.reduce(:or)
    }

    # Quoted phrases
    remainder.scan(/"([^"]+)"/).each do |(phrase)|
      remainder = remainder.sub("\"#{phrase}\"", "")
      scope = scope.where(build_or_cond.call(phrase))
    end

    # WITHOUT / -word
    remainder.scan(/(?:WITHOUT\s+|-)([\S]+)/i).each do |(word)|
      remainder = remainder.sub(/(?:WITHOUT\s+|-)#{Regexp.escape(word)}/i, "")
      scope = scope.where.not(build_or_cond.call(word))
    end

    remainder = remainder.strip
    return scope if remainder.blank?

    # OR groups
    if remainder.match?(/\bOR\b/i)
      or_terms = remainder.split(/\bOR\b/i).map(&:strip).reject(&:blank?)
      or_cond  = or_terms.map { |w| build_or_cond.call(w) }.reduce(:or)
      scope = scope.where(or_cond)
    else
      # AND: each remaining word
      remainder.split.each { |w| scope = scope.where(build_or_cond.call(w)) }
    end

    scope
  end

  # ── Status ─────────────────────────────────────────────────────────────────

  def apply_status(scope)
    values = Array(@params[:status]).reject(&:blank?)
    return scope if values.empty?
    scope.where(status: values)
  end

  # ── Boolean flags ──────────────────────────────────────────────────────────

  def apply_booleans(scope)
    scope = scope.where(material_to_read: true) if @params[:to_read].present?
    scope = scope.where(lead_title: true)        if @params[:lead_title].present?
    scope = scope.where(tracking_material: true) if @params[:tracking_material].present?
    scope
  end

  # ── Genres / Sub-genres / Client types ────────────────────────────────────

  def apply_genres(scope)
    ids = array_param(:genre_ids)
    return scope if ids.empty?
    scope.joins(:book_genres).where(book_genres: { genre_id: ids })
  end

  def apply_sub_genres(scope)
    ids = array_param(:sub_genre_ids)
    return scope if ids.empty?
    scope.joins(:book_sub_genres).where(book_sub_genres: { sub_genre_id: ids })
  end

  def apply_client_types(scope)
    ids = array_param(:client_type_ids)
    return scope if ids.empty?
    scope.joins(:book_client_types).where(book_client_types: { client_type_id: ids })
  end

  # ── Authors ────────────────────────────────────────────────────────────────

  def apply_authors(scope)
    ids = array_param(:author_ids)
    return scope if ids.empty?
    scope.joins(:book_authors).where(book_authors: { author_id: ids })
  end

  # ── Companies by role ──────────────────────────────────────────────────────

  def apply_companies(scope)
    {
      agency_company_ids:        :agency,
      film_agency_company_ids:   :film_agency,
      publisher_company_ids:     :publisher,
      editor_company_ids:        :editor
    }.each do |param_key, role|
      ids = array_param(param_key)
      next if ids.empty?
      scope = scope.joins(:book_companies)
                   .where(book_companies: { role: BookCompany.roles[role], company_id: ids })
    end

    # Rights holders (two roles)
    ids = array_param(:rights_holder_company_ids)
    unless ids.empty?
      scope = scope.joins(:book_companies)
                   .where(book_companies: {
                     role: [BookCompany.roles[:rights_holder], BookCompany.roles[:secondary_rights_holder]],
                     company_id: ids
                   })
    end

    scope
  end

  # ── Contacts by role ───────────────────────────────────────────────────────

  def apply_contacts(scope)
    {
      agent_contact_ids:      :agent,
      film_agent_contact_ids: :film_agent
    }.each do |param_key, role|
      ids = array_param(param_key)
      next if ids.empty?
      scope = scope.joins(:book_contacts)
                   .where(book_contacts: { role: BookContact.roles[role], contact_id: ids })
    end
    scope
  end

  # ── Client activities ──────────────────────────────────────────────────────

  def apply_client_activities(scope)
    ca_companies = array_param(:client_activity_company_ids)
    unless ca_companies.empty?
      scope = scope.joins(:client_activities).where(client_activities: { company_id: ca_companies })
    end

    ca_contacts = array_param(:client_activity_contact_ids)
    unless ca_contacts.empty?
      scope = scope.joins(:client_activities).where(client_activities: { contact_id: ca_contacts })
    end

    activity_types = Array(@params[:activity_types]).reject(&:blank?)
    unless activity_types.empty?
      scope = scope.joins(:client_activities).where(client_activities: { activity_type: activity_types })
    end

    scope
  end

  # ── Scouts ─────────────────────────────────────────────────────────────────

  def apply_scouts(scope)
    ids = array_param(:scout_ids)
    return scope if ids.empty?
    scope.where(primary_scout_id: ids).or(scope.where(secondary_scout_id: ids))
  end

  # ── Readers ────────────────────────────────────────────────────────────────

  def apply_readers(scope)
    ids = array_param(:reader_ids)
    return scope if ids.empty?
    scope.joins(:readers_reports).where(readers_reports: { reader_id: ids })
  end

  # ── Rights sold text ───────────────────────────────────────────────────────

  def apply_rights_sold_text(scope)
    val = @params[:rights_sold_text].to_s.strip
    return scope if val.blank?
    t = Book.arel_table
    scope.where(t[:rights_sold_plain].matches("%#{val.gsub('%', '').gsub('_', '')}%"))
  end

  # ── Date ranges ────────────────────────────────────────────────────────────

  def apply_date_ranges(scope)
    scope = apply_range(scope, :updated_at,    :updated_after,   :updated_before)
    scope = apply_range(scope, :created_at,    :entered_after,   :entered_before)
    scope = apply_range(scope, :delivery_date, :delivered_after, :delivered_before)
    scope = apply_range(scope, :followup_date, :followup_after,  :followup_before)

    # Publication year (integer range)
    after  = @params[:published_after].presence
    before = @params[:published_before].presence
    if after.present? || before.present?
      min_year = after.to_i  if after.present?
      max_year = before.to_i if before.present?
      if min_year && max_year
        scope = scope.where(publication_year: min_year..max_year)
      elsif min_year
        scope = scope.where(publication_year: min_year..)
      else
        scope = scope.where(publication_year: ..max_year)
      end
    end

    # Activity date
    scope = apply_joined_range(scope, :client_activities, :date, :activity_after, :activity_before)

    # Report date
    scope = apply_joined_range(scope, :readers_reports, :report_date, :read_after, :read_before)

    scope
  end

  def apply_range(scope, column, after_key, before_key)
    after  = @params[after_key].presence
    before = @params[before_key].presence
    return scope unless after.present? || before.present?

    if after.present? && before.present?
      scope.where(column => after..before)
    elsif after.present?
      scope.where(column => after..)
    else
      scope.where(column => ..before)
    end
  end

  def apply_joined_range(scope, join_table, column, after_key, before_key)
    after  = @params[after_key].presence
    before = @params[before_key].presence
    return scope unless after.present? || before.present?

    if after.present? && before.present?
      scope.joins(join_table).where(join_table => { column => after..before })
    elsif after.present?
      scope.joins(join_table).where(join_table => { column => after.. })
    else
      scope.joins(join_table).where(join_table => { column => ..before })
    end
  end

  # ── Helpers ────────────────────────────────────────────────────────────────

  def array_param(key)
    Array(@params[key]).map(&:to_i).reject(&:zero?)
  end
end
