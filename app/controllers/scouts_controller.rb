class ScoutsController < ApplicationController
  before_action :set_scout, only: %i[ show edit update destroy ]

  # GET /scouts or /scouts.json
  def index
    @scouts = Scout.all
  end

  # GET /scouts/1 or /scouts/1.json
  def show
  end

  # GET /scouts/new
  def new
    @scout = Scout.new
  end

  # GET /scouts/1/edit
  def edit
  end

  # POST /scouts or /scouts.json
  def create
    @scout = Scout.new(scout_params)

    respond_to do |format|
      if @scout.save
        format.html { redirect_to @scout, notice: "Scout was successfully created." }
        format.json { render :show, status: :created, location: @scout }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @scout.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /scouts/1 or /scouts/1.json
  def update
    respond_to do |format|
      if @scout.update(scout_params)
        format.html { redirect_to @scout, notice: "Scout was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @scout }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @scout.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /scouts/1 or /scouts/1.json
  def destroy
    @scout.destroy!

    respond_to do |format|
      format.html { redirect_to scouts_path, notice: "Scout was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_scout
      @scout = Scout.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def scout_params
      params.expect(scout: [ :name, :specialty, :notes ])
    end
end
