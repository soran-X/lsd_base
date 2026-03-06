module ReportRenderers
  # Default renderer — used for: Reading List, Follow Up List, YA Highlights, Netflix Report.
  # Grouping + completeness logic lives in ReportTypeStrategies::Base (flat, all complete).
  # This class is responsible only for how each individual book is rendered.
  class DefaultRenderer < Base
    private

    def render_book(book)
      authors   = book.credited_authors.map(&:full_name).join(", ")
      publisher = book.book_companies.find { |bc| bc.role == "publisher" }&.company&.name
      pub_date  = [ book.publication_season, book.publication_year ].compact_blank.join(" ")

      <<~HTML
        <div class="report-book default-entry">
          <p class="book-title-line"><strong>#{esc(book.title)}</strong>#{authors.present? ? " by #{esc(authors)}" : ""}</p>
          #{field_row("Publisher", publisher)}
          #{field_row("Pub Date",  pub_date)}
          #{html_field_row("Synopsis", book.synopsis)}
        </div>
      HTML
    end
  end
end
