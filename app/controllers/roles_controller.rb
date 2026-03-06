class RolesController < ApplicationController
  before_action :require_admin!
  before_action :set_role, only: %i[show edit update destroy]

  def index
    @roles = Role.ordered
  end

  def show; end

  def new
    @role = Role.new
  end

  def create
    @role = Role.new(role_params)

    if Current.user.hierarchy_level < @role.hierarchy_level.to_i
      redirect_to roles_path, alert: "Cannot create a role with higher hierarchy than your own."
      return
    end

    if @role.save
      redirect_to roles_path, notice: "Role created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    Permission.sync_all!
    @all_resources  = Permission::ALL_PERMISSIONS.keys
    @all_actions    = %w[index show new edit destroy]
    @permission_map = Permission.all.index_by { |p| "#{p.resource}:#{p.action}" }
    @granted_ids    = @role.permission_ids.to_set
  end

  def update
    if Current.user.hierarchy_level < role_params[:hierarchy_level].to_i
      redirect_to roles_path, alert: "Cannot assign hierarchy level higher than your own."
      return
    end

    if @role.update(role_params.except(:permission_ids))
      @role.permission_ids = role_params[:permission_ids] || []
      redirect_to roles_path, notice: "Role updated."
    else
      Permission.sync_all!
      @all_resources  = Permission::ALL_PERMISSIONS.keys
      @all_actions    = %w[index show new edit destroy]
      @permission_map = Permission.all.index_by { |p| "#{p.resource}:#{p.action}" }
      @granted_ids    = @role.permission_ids.to_set
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @role.hierarchy_level > Current.user.hierarchy_level
      redirect_to roles_path, alert: "Cannot delete a role with higher hierarchy than your own."
      return
    end
    @role.destroy
    redirect_to roles_path, notice: "Role deleted."
  end

  private
    def set_role
      @role = Role.find(params[:id])
    end

    def role_params
      params.require(:role).permit(:name, :hierarchy_level, permission_ids: [])
    end
end
