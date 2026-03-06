module ReportRenderers
  class Base
    attr_reader :report

    def initialize(report)
      @report = report
    end

    def render
      render_html
    end

    private

    # ── Strategy ────────────────────────────────────────────────────────────

    def strategy
      @strategy ||= ReportTypeStrategies::Base.for(report.report_type)
    end

    # ── Books (eager-loaded) ─────────────────────────────────────────────────

    def books
      @books ||= report.books
        .includes(
          :credited_authors, :translators,
          :genres, :sub_genres, :client_types,
          book_companies: { company: [:contacts, { company_subagents: [:territory, { subagent_company: :contacts }] }] },
          book_contacts:  :contact,
          film_tracking:  :film_genres
        )
        .order("report_books.position")
    end

    # ── Rendering ────────────────────────────────────────────────────────────

    # Groups books via the strategy, then renders each group.
    # Subclasses only need to override `render_book`.
    def render_html
      groups = strategy.build_groups(books)
      wrap_report(render_groups(groups))
    end

    # Iterates the nested group structure and produces section HTML.
    def render_groups(groups)
      html = ""
      groups.each do |cat_group|
        if cat_group[:incomplete]
          html += render_incomplete_group(cat_group)
          next
        end

        cat_group[:sections].each do |sec|
          heading = [ cat_group[:category], sec[:section] ].compact_blank.join(" \u25B6 ")
          if heading.present?
            html += %(<div class="report-section">)
            html += %(<h2 class="report-section-heading">#{esc(heading)}</h2>)
          end

          sec[:genres].each do |g|
            html += %(<h3 class="report-genre-heading">#{esc(g[:genre])}</h3>) if g[:genre].present?
            g[:books].each { |b| html += render_book(b) }
          end

          html += "</div>" if heading.present?
        end
      end
      html
    end

    # Incomplete group: heading + title-only list (no book detail).
    def render_incomplete_group(cat_group)
      html  = %(<h2 class="report-section-heading">#{esc(cat_group[:category])}</h2>)
      books = cat_group[:sections].flat_map { |s| s[:genres].flat_map { |g| g[:books] } }
      books.each { |b| html += %(<p class="report-field">#{esc(b.title)}</p>) }
      html
    end

    # ── Subclass interface ────────────────────────────────────────────────────

    def render_book(_book)
      raise NotImplementedError, "#{self.class} must implement render_book"
    end

    # ── Helpers ───────────────────────────────────────────────────────────────

    def esc(str)
      CGI.escapeHTML(str.to_s)
    end

    def plain(html)
      html.to_s.gsub(/<[^>]+>/, " ").gsub(/&[a-zA-Z]+;|&#\d+;/, " ").squish
    end

    def field_row(label, value)
      return "" if value.blank?
      %(<p class="report-field"><span class="report-label">#{esc(label)}:</span> #{esc(value)}</p>)
    end

    def html_field_row(label, html_value)
      return "" if html_value.blank?
      %(<div class="report-field"><span class="report-label">#{esc(label)}:</span> <span class="report-rich-value trix-content">#{html_value}</span></div>)
    end

    def wrap_report(sections_html)
      <<~HTML
        <div class="report-body trix-content">#{report.body.to_s}</div>
        <div class="report-books">#{sections_html}</div>
        <div class="report-footer trix-content">#{report.footer.to_s}</div>
      HTML
    end
  end
end
