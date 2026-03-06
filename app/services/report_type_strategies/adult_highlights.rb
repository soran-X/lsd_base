module ReportTypeStrategies
  # Adult Highlights (also used for YA Highlights)
  #
  # Completeness: book must have authors, genres, AND sub_genres.
  #
  # Grouping:
  #   Titles with Incomplete Info  ← books missing required fields (title-only)
  #   [Fiction | Non-Fiction]
  #     [New Mention | Updates]
  #       [Genre sub-heading]
  #         books...
  #
  # To change completeness rules:  edit `complete?`
  # To change category logic:      edit `genre_category`
  # To add new sections/ordering:  edit CATEGORY_ORDER / SECTION_ORDER
  class AdultHighlights < Base
    CATEGORY_ORDER = Genre.pluck(:name).uniq.freeze
    SECTION_ORDER  = ["New Mention", "Updates"].freeze

    def required_fields
      {
        "Authors"    => ->(b) { b.credited_authors.present? },
        "Genres"     => ->(b) { b.genres.present? },
        "Sub-genres" => ->(b) { b.sub_genres.present? }
      }
    end

    def build_groups(books)
      complete, incomplete = books.partition { |b| complete?(b) }

      result = incomplete_group(incomplete)

      group_data = {}
      complete.each do |book|
        genre_names = book.genres.map(&:name)
        genre_names = ["Uncategorized"] if genre_names.empty?
        section = book.update_tagline.present? ? "Updates" : "New Mention"

        genre_names.each do |genre|
          cat = genre_category(genre)
          group_data[cat] ||= {}
          group_data[cat][section] ||= {}
          group_data[cat][section][genre] ||= []
          group_data[cat][section][genre] << book
        end
      end

      CATEGORY_ORDER.each do |cat|
        next unless group_data.key?(cat)
        sections = SECTION_ORDER.filter_map do |sec|
          genre_map = group_data.dig(cat, sec)
          next if genre_map.blank?
          { section: sec, genres: genre_map.map { |genre, bks| { genre: genre, books: bks } } }
        end
        result << { category: cat, incomplete: false, sections: sections } if sections.any?
      end

      result
    end

    private

    # Derives Fiction / Non-Fiction from genre name.
    # Edit this list to reclassify genres.
    def genre_category(genre_name)
      lower = genre_name.downcase
      return "Non-Fiction" if lower.include?("non-fiction") || lower.include?("nonfiction")
      return "Fiction"     if lower.include?("fiction")
      return genre_name
    end
  end
end
