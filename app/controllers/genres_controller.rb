class GenresController < ApplicationController
  before_action -> { authorize!(:index,   :genres) }, only: %i[index]
  before_action -> { authorize!(:new,     :genres) }, only: %i[new create]
  before_action -> { authorize!(:edit,    :genres) }, only: %i[edit update]
  before_action -> { authorize!(:destroy, :genres) }, only: %i[destroy]
  before_action :set_genre, only: %i[edit update destroy]

  def index
    @genres = Genre.ordered
  end

  def new
    @genre = Genre.new
  end

  def create
    @genre = Genre.new(genre_params)
    if @genre.save
      redirect_to genres_path, notice: "Genre \"#{@genre.name}\" created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @genre.update(genre_params)
      redirect_to genres_path, notice: "\"#{@genre.name}\" updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @genre.name
    @genre.destroy!
    redirect_to genres_path, notice: "\"#{name}\" deleted.", status: :see_other
  end

  private

  def set_genre
    @genre = Genre.find(params.expect(:id))
  end

  def genre_params
    params.expect(genre: [:name])
  end
end
