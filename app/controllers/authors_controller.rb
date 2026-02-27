class AuthorsController < ApplicationController
  before_action :set_author, only: %i[show edit update destroy]

  # GET /authors
  def index
    @authors = Author.kept.order(:last_name, :first_name)
  end

  # GET /authors/search.json?q=García
  def search
    results = if params[:q].present?
      Author.kept.search_by_name(params[:q]).limit(12)
    else
      Author.kept.order(:last_name, :first_name).limit(12)
    end

    render json: results.map { |a| { id: a.id, label: a.display_name } }
  end

  # GET /authors/1
  def show
  end

  # GET /authors/new
  def new
    @author = Author.new
  end

  # GET /authors/1/edit
  def edit
  end

  # POST /authors
  def create
    @author = Author.new(author_params)

    respond_to do |format|
      if @author.save
        format.html { redirect_to @author, notice: "Author was successfully created." }
        format.json { render json: { id: @author.id, label: @author.display_name }, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @author.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /authors/1
  def update
    respond_to do |format|
      if @author.update(author_params)
        format.html { redirect_to @author, notice: "Author was successfully updated.", status: :see_other }
        format.json { render json: { id: @author.id, label: @author.display_name } }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @author.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /authors/1
  def destroy
    @author.discard!

    respond_to do |format|
      format.html { redirect_to authors_path, notice: "Author was successfully removed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_author
    @author = Author.kept.find(params.expect(:id))
  end

  def author_params
    params.expect(author: [:first_name, :last_name, :bio])
  end
end
