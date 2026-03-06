module ReportTypeStrategies
  # Base strategy: all books are complete, single flat group, no headings.
  # Subclass and override `complete?` and/or `build_groups` to customise.
  #
  # `build_groups` returns:
  #   [
  #     {
  #       category:   String | nil,   # h2 heading (e.g. "Fiction", "Out For Film")
  #       incomplete: Boolean,         # true → render as warning / title-only in print
  #       sections: [
  #         {
  #           section: String | nil,   # h3 heading (e.g. "New Mention")
  #           genres: [
  #             { genre: String | nil, books: [Book, ...] }
  #           ]
  #         }
  #       ]
  #     }
  #   ]
  class Base
    # ── Public interface ────────────────────────────────────────────────────

    # Override in subclasses with a hash of { "Label" => ->(book) { check } }.
    # Used to derive both complete? and the list of missing fields shown in the UI.
    def required_fields
      {}
    end

    def complete?(book)
      required_fields.all? { |_, check| check.call(book) }
    end

    def missing_fields(book)
      required_fields.reject { |_, check| check.call(book) }.keys
    end

    # Override in subclasses to define grouping for this report type.
    def build_groups(books)
      flat_group(books)
    end

    # ── Factory ─────────────────────────────────────────────────────────────

    def self.for(report_type)
      case report_type
      when "adult_highlights", "ya_highlights" then AdultHighlights.new
      when "film_memo"                          then FilmMemo.new
      else                                           Base.new
      end
    end

    private

    # Single group with no headings — used by default and as a building block.
    def flat_group(books, label: nil)
      [{
        category:   label,
        incomplete: false,
        sections:   [{ section: nil, genres: [{ genre: nil, books: books.to_a }] }]
      }]
    end

    # Incomplete-books group (title-only in rendered output, warning in show UI).
    def incomplete_group(books)
      return [] if books.empty?
      [{
        category:   "Titles with Incomplete Info",
        incomplete: true,
        sections:   [{ section: nil, genres: [{ genre: nil, books: books.to_a }] }]
      }]
    end
  end
end
