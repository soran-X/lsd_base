module ReportsHelper
  # Groups report_books for display on the show page, mirroring the rendered
  # report structure. Delegates grouping + completeness to the same
  # ReportTypeStrategy used by the renderer — one source of truth.
  #
  # For incomplete groups, also includes `missing_by_book: { book_id => ["Authors", ...] }`
  # so the template can display which fields need attention.
  def group_report_books_for_show(report, report_books)
    strategy   = ReportTypeStrategies::Base.for(report.report_type)
    rb_by_book = report_books.index_by(&:book_id)
    groups     = strategy.build_groups(report_books.map(&:book))

    groups.map do |cat_group|
      {
        category:   cat_group[:category],
        incomplete: cat_group[:incomplete],
        sections:   cat_group[:sections].map do |sec|
          {
            section: sec[:section],
            genres:  sec[:genres].map do |g|
              rbs            = g[:books].filter_map { |b| rb_by_book[b.id] }
              missing_by_book = cat_group[:incomplete] \
                ? g[:books].to_h { |b| [ b.id, strategy.missing_fields(b) ] } \
                : {}

              { genre: g[:genre], report_books: rbs, missing_by_book: missing_by_book }
            end
          }
        end
      }
    end
  end
end
