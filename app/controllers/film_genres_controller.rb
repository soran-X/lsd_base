class FilmGenresController < ApplicationController
  before_action :require_admin, except: :search
  before_action :set_film_genre, only: %i[edit update destroy]

  def index
    @film_genres = FilmGenre.ordered
  end

  def new
    @film_genre = FilmGenre.new
  end

  def create
    @film_genre = FilmGenre.new(film_genre_params)
    respond_to do |format|
      if @film_genre.save
        format.html { redirect_to film_genres_path, notice: "Film genre \"#{@film_genre.name}\" created." }
        format.json { render json: { id: @film_genre.id, label: @film_genre.name }, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @film_genre.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    if @film_genre.update(film_genre_params)
      redirect_to film_genres_path, notice: "\"#{@film_genre.name}\" updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @film_genre.name
    @film_genre.destroy!
    redirect_to film_genres_path, notice: "\"#{name}\" deleted.", status: :see_other
  end

  def search
    q = params[:q].to_s.strip
    genres = q.present? ? FilmGenre.search_by_name(q).limit(10) : FilmGenre.ordered.limit(10)
    render json: genres.map { |g| { id: g.id, label: g.name } }
  end

  private

  def set_film_genre
    @film_genre = FilmGenre.find(params.expect(:id))
  end

  def film_genre_params
    params.expect(film_genre: [:name])
  end

  def require_admin
    redirect_to root_path, alert: "Not authorized." unless Current.user.hierarchy_level >= 50
  end
end
