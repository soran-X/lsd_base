module ReportRenderers
  class CustomRenderer < Base
    private

    def render_html
      template = report.custom_report_template
      return wrap_report("") unless template

      keys = template.field_keys
      section_names = template.sections.map(&:name)

      if section_names.any?
        render_with_sections(keys, section_names)
      else
        render_flat(keys)
      end
    end

    def render_with_sections(keys, section_names)
      # Build map: book_id => custom_section
      section_map = report.report_books.each_with_object({}) do |rb, h|
        h[rb.book_id] = rb.custom_section.presence || ""
      end

      # Group books by section in template section order
      books_by_section = section_names.each_with_object({}) { |name, h| h[name] = [] }
      books_by_section[""] = []

      books.each do |book|
        sec = section_map[book.id] || ""
        if books_by_section.key?(sec)
          books_by_section[sec] << book
        else
          books_by_section[""] << book
        end
      end

      html = ""
      section_names.each do |name|
        group = books_by_section[name]
        next if group.empty?
        html += %(<div class="report-section">)
        html += %(<h2 class="report-section-heading">#{esc(name)}</h2>)
        group.each { |b| html += render_book_fields(b, keys) }
        html += "</div>"
      end

      # Books without a matching section
      ungrouped = books_by_section[""]
      unless ungrouped.empty?
        html += %(<div class="report-section">)
        ungrouped.each { |b| html += render_book_fields(b, keys) }
        html += "</div>"
      end

      wrap_report(html)
    end

    def render_flat(keys)
      html = books.map { |b| render_book_fields(b, keys) }.join
      wrap_report(html)
    end

    def render_book(_book)
      # Not used directly — render_html is overridden
    end

    def render_book_fields(book, keys)
      html = %(<div class="report-book custom-entry">)
      keys.each { |key| html += render_field(book, key) }
      html += "</div>"
      html
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
    def render_field(book, key)
      ft = book.film_tracking

      case key
      when "title"
        authors = book.credited_authors.map(&:full_name).join(", ")
        line = "<strong>#{esc(book.title)}</strong>"
        line += " by #{esc(authors)}" if authors.present?
        %(<p class="book-title-line">#{line}</p>)
      when "subtitle"
        field_row("Subtitle", book.subtitle)
      when "old_title"
        field_row("Old Title", book.respond_to?(:old_title) ? book.old_title : nil)
      when "status"
        field_row("Status", book.status&.humanize)
      when "publication_year"
        field_row("Publication Year", book.publication_year)
      when "publication_season"
        field_row("Publication Season", book.publication_season)
      when "genres"
        field_row("Genres", book.genres.map(&:name).join(", "))
      when "sub_genres"
        field_row("Sub-Genres", book.sub_genres.map(&:name).join(", "))
      when "lead_title"
        val = book.respond_to?(:lead_title) ? book.lead_title : nil
        field_row("Lead Title", val ? "Yes" : nil)
      when "update_tagline"
        field_row("Update Tagline", book.respond_to?(:update_tagline) ? book.update_tagline : nil)
      when "publisher"
        pub = book.book_companies.find { |bc| bc.role == "publisher" }&.company&.name
        field_row("Publisher", pub)
      when "agency"
        agency = book.book_companies.select { |bc| bc.role == "agency" }.map { |bc| bc.company.name }.join(", ")
        field_row("Literary Agency", agency)
      when "agents"
        agents = book.book_contacts.select { |bc| bc.role == "agent" }.map { |bc| bc.contact.display_name }.join(", ")
        field_row("Literary Agent(s)", agents)
      when "film_agency"
        fa = book.book_companies.select { |bc| bc.role == "film_agency" }.map { |bc| bc.company.name }.join(", ")
        field_row("Film Agency", fa)
      when "film_agents"
        fa = book.book_contacts.select { |bc| bc.role == "film_agent" }.map { |bc| bc.contact.display_name }.join(", ")
        field_row("Film Agent(s)", fa)
      when "subagents"
        subs = book.book_companies.flat_map do |bc|
          bc.company.company_subagents.map do |sa|
            parts = [ sa.subagent_company.name, sa.territory&.name ].compact_blank
            parts.join(" / ")
          end
        end.compact_blank.uniq
        field_row("Subagents", subs.join("; "))
      when "synopsis"
        html_field_row("Synopsis", book.synopsis)
      when "log_line"
        field_row("Log Line", book.respond_to?(:log_line) ? book.log_line : nil)
      when "pub_info"
        pub_date = [ book.publication_season, book.publication_year ].compact_blank.join(" ")
        pub_name = book.book_companies.find { |bc| bc.role == "publisher" }&.company&.name
        field_row("Pub Info", [ pub_name, pub_date.presence ].compact_blank.join(", "))
      when "material"
        html_field_row("Material", ft&.material)
      when "rights_sold"
        field_row("Rights Sold", book.respond_to?(:rights_sold) ? book.rights_sold : nil)
      when "primary_scout"
        field_row("Primary Scout", book.primary_scout&.display_name)
      when "secondary_scout"
        field_row("Secondary Scout", book.secondary_scout&.display_name)
      when "film_flag"
        val = ft&.film_flag
        val ? field_row("Film Flag", val.to_s.humanize) : ""
      when "film_synopsis"
        html_field_row("Film Synopsis", ft&.film_synopsis)
      when "film_option"
        field_row("Film Option", ft&.film_option)
      when "readers_thoughts"
        html_field_row("Reader's Thoughts", ft&.readers_thoughts)
      when "film_genre"
        genres = ft&.film_genres&.map(&:name)&.join(", ")
        field_row("Film Genre", genres)
      else
        ""
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength
  end
end
