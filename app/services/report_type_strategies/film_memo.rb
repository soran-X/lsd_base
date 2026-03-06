module ReportTypeStrategies
  # Film Memo
  #
  # Completeness: book must have a film_flag set ("Out for Film" or "Pub Buzz").
  #
  # Grouping:
  #   Titles with Incomplete Info  ← no film_flag (title-only)
  #   Out For Film                 ← film_flag == "Out for Film"
  #   Pub Buzz                     ← film_flag == "Pub Buzz"
  #
  # To add a new film category: add its flag value + a flat_group line in build_groups.
  class FilmMemo < Base
    def required_fields
      {
        "Film Flag (Out for Film / Pub Buzz)" => ->(b) { b.film_tracking&.film_flag.present? }
      }
    end

    def build_groups(books)
      off_books  = books.select { |b| b.film_tracking&.film_flag == "Out for Film" }
      buzz_books = books.select { |b| b.film_tracking&.film_flag == "Pub Buzz" }
      incomplete = books.reject { |b| b.film_tracking&.film_flag.present? }

      result  = incomplete_group(incomplete)
      result += flat_group(off_books,  label: "Out For Film") if off_books.any?
      result += flat_group(buzz_books, label: "Pub Buzz")     if buzz_books.any?
      result
    end
  end
end
