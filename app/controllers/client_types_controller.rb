class ClientTypesController < ApplicationController
  before_action :require_admin
  before_action :set_client_type, only: %i[edit update destroy]

  def index
    @client_types = ClientType.ordered
  end

  def new
    @client_type = ClientType.new
  end

  def create
    @client_type = ClientType.new(client_type_params)
    if @client_type.save
      redirect_to client_types_path, notice: "\"#{@client_type.name}\" created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @client_type.update(client_type_params)
      redirect_to client_types_path, notice: "\"#{@client_type.name}\" updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @client_type.name
    @client_type.destroy!
    redirect_to client_types_path, notice: "\"#{name}\" deleted.", status: :see_other
  end

  private

  def set_client_type
    @client_type = ClientType.find(params.expect(:id))
  end

  def client_type_params
    params.expect(client_type: [:name])
  end

  def require_admin
    redirect_to root_path, alert: "Not authorized." unless Current.user.hierarchy_level >= 50
  end
end
