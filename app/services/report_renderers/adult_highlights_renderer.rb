module ReportRenderers
  # Adult Highlights renderer.
  # Grouping + completeness logic lives in ReportTypeStrategies::AdultHighlights.
  # This class is responsible only for how each individual book is rendered.
  class AdultHighlightsRenderer < Base
    private

    def render_book(book)
      authors   = book.credited_authors.map { |a| a.display_name.upcase }.join(", ")
      publisher = book.book_companies.find { |bc| bc.role == "publisher" }&.company&.name
      agencies  = book.book_companies.select { |bc| bc.role == "agency" }.map { |bc| bc.company.name }.join(", ")
      pub_date  = [ book.publication_season, book.publication_year ].compact_blank.join(" ")
      subagents = format_subagents(book)

      html  = %(<div class="report-book adult-highlights-entry">)
      html += %(<p class="book-authors">#{esc(authors)}</p>)             if authors.present?
      html += %(<p class="book-title">#{esc(book.title)}</p>)
      html += %(<p class="book-tagline">&#9654; #{esc(book.update_tagline)}</p>) if book.update_tagline.present?
      html += field_row("Publisher",   publisher)
      html += %(<p class="report-field"><span class="report-label">Agency:</span> #{esc(agencies)}</p>)
      html += field_row("Pub Date",    pub_date)
      html += field_row("Subagents",   subagents)
      html += html_field_row("Description", book.synopsis)
      html += html_field_row("Info",        book.pub_info)
      html += html_field_row("Material",    book.material)
      html += html_field_row("Update",      book.notes)    if book.notes.present?
      html += html_field_row("Rights Sold", book.rights_sold)
      html += "</div>"
      html
    end

    # ── Subagent formatting ──────────────────────────────────────────────────

    def format_subagents(book)
      companies = book.book_companies
                      .select { |bc| %w[publisher agency rights_holder].include?(bc.role) }
                      .map(&:company)
                      .select { |c| c.company_subagents.any? }
      return "" if companies.empty?

      companies.map do |company|
        entries = company.company_subagents.map do |sa|
          territory = sa.territory&.name || "ALL"
          sub       = sa.subagent_company

          if sub.nil? || sub.id == company.id
            contact = company.contacts.find { |c| c.email.present? } || company.contacts.first
            if contact
              name  = [ contact.first_name, contact.last_name ].compact_blank.join(" ")
              email = contact.email.presence
              label = email ? "#{name} [#{email}]" : name
              "(#{territory}) Direct: #{label}"
            else
              "(#{territory}) DIRECT"
            end
          else
            contact = sub.contacts.find { |c| c.email.present? } || sub.contacts.first
            if contact
              name  = [ contact.first_name, contact.last_name ].compact_blank.join(" ")
              email = contact.email.presence
              label = email ? "#{name} [#{email}]" : name
              "(#{territory}) #{esc(sub.name)}: #{label}"
            else
              "(#{territory}) #{esc(sub.name)}"
            end
          end
        end.join(", ")

        "#{esc(company.name)} : #{entries}"
      end.join("\n")
    end
  end
end
