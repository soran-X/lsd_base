class SubgenresController < ApplicationController
  before_action :require_admin
  before_action :set_subgenre, only: %i[edit update destroy]

  def index
    @subgenres = SubGenre.ordered
  end

  def new
    @subgenre = SubGenre.new
  end

  def create
    @subgenre = SubGenre.new(subgenre_params)
    if @subgenre.save
      redirect_to subgenres_path, notice: "Subgenre \"#{@subgenre.name}\" created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @subgenre.update(subgenre_params)
      redirect_to subgenres_path, notice: "\"#{@subgenre.name}\" updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @subgenre.name
    @subgenre.destroy!
    redirect_to subgenres_path, notice: "\"#{name}\" deleted.", status: :see_other
  end

  private

  def set_subgenre
    @subgenre = SubGenre.find(params.expect(:id))
  end

  def subgenre_params
    params.expect(sub_genre: [:name])
  end

  def require_admin
    redirect_to root_path, alert: "Not authorized." unless Current.user.hierarchy_level >= 50
  end
end
