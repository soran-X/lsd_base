class SearchController < ApplicationController
  def index
    q = params[:q].to_s.strip
    return render(json: []) if q.length < 2

    books = Book.kept.search_globally(q).limit(12)
    books = books.where(confidential: false) unless Current.user.hierarchy_level >= 50

    render json: books.map { |b|
      authors = b.credited_authors.map(&:display_name).join(", ")
      {
        id:      b.id,
        title:   b.title,
        authors: authors,
        url:     Rails.application.routes.url_helpers.book_path(b)
      }
    }
  end
end
