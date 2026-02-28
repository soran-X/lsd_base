class TerritoriesController < ApplicationController
  before_action :require_admin
  before_action :set_territory, only: %i[edit update destroy]

  def index
    @territories = Territory.ordered
  end

  def new
    @territory = Territory.new
  end

  def create
    @territory = Territory.new(territory_params)
    if @territory.save
      redirect_to territories_path, notice: "Territory \"#{@territory.name}\" created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @territory.update(territory_params)
      redirect_to territories_path, notice: "Territory updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @territory.name
    @territory.destroy!
    redirect_to territories_path, notice: "\"#{name}\" deleted.", status: :see_other
  end

  private

  def set_territory
    @territory = Territory.find(params.expect(:id))
  end

  def territory_params
    params.expect(territory: [:name])
  end

  def require_admin
    redirect_to root_path, alert: "Not authorized." unless Current.user.hierarchy_level >= 50
  end
end
