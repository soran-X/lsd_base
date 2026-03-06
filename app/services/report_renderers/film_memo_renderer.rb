module ReportRenderers
  # Film Memo renderer.
  # Grouping + completeness logic lives in ReportTypeStrategies::FilmMemo.
  # This class is responsible only for how each individual book is rendered.
  class FilmMemoRenderer < Base
    private

    def render_book(book)
      ft            = book.film_tracking
      authors       = book.credited_authors.map { |a| a.display_name.upcase }.join(", ")
      film_agents   = book.book_contacts.select { |bc| bc.role == "film_agent" }
                          .map { |bc| bc.contact.display_name }.join(", ")
      film_agencies = book.book_companies.select { |bc| bc.role == "film_agency" }
                          .map { |bc| bc.company.name }.join(", ")
      lit_agents    = book.book_contacts.select { |bc| bc.role == "agent" }
                          .map { |bc| bc.contact.display_name }.join(", ")
      agencies      = book.book_companies.select { |bc| bc.role == "agency" }
                          .map { |bc| bc.company.name }.join(", ")
      publisher     = book.book_companies.find { |bc| bc.role == "publisher" }&.company&.name
      pub_date      = [ book.publication_season, book.publication_year ].compact_blank.join(" ")
      pub_str       = [ publisher, pub_date.present? ? "(#{pub_date})" : nil ].compact_blank.join(" ")

      <<~HTML
        <div class="report-book film-memo-entry">
          <p class="book-title-line">
            <strong>#{esc(book.title)}</strong>#{authors.present? ? " by #{esc(authors)}" : ""}
          </p>
          #{field_row("Film Agent(s)",       film_agents)}
          #{field_row("Film Agency",         film_agencies)}
          #{field_row("Literary Agent",      lit_agents)}
          #{field_row("Literary Agency",     agencies)}
          #{field_row("Publisher",           pub_str)}
          #{html_field_row("Comments",       ft&.comments)}
          #{html_field_row("Synopsis",       ft&.film_synopsis)}
          #{html_field_row("Material",       ft&.material)}
          #{html_field_row("Reader's Thoughts", ft&.readers_thoughts)}
        </div>
      HTML
    end
  end
end
