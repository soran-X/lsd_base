class ReportsController < ApplicationController
  before_action -> { authorize!(:index,   :reports) }, only: %i[index show render_html edit_display update_display]
  before_action -> { authorize!(:new,     :reports) }, only: %i[new create]
  before_action -> { authorize!(:edit,    :reports) }, only: %i[edit update reset_display reorder]
  before_action -> { authorize!(:destroy, :reports) }, only: %i[destroy]
  before_action :set_report, only: %i[show edit update destroy render_html edit_display update_display reset_display reorder]

  def index
    @reports = accessible_reports
                 .order(pinned: :desc, report_date: :desc, created_at: :desc)
                 .includes(:client_types, :created_by, :report_books)
  end

  def show
    @report_books = @report.report_books
                           .includes(book: [
                             :credited_authors, :genres, :sub_genres, :film_tracking,
                             :primary_scout, :secondary_scout,
                             { book_companies: :company }
                           ])
                           .order(:position)
  end

  def new
    @report          = Report.new(report_date: Date.current)
    @client_types    = ClientType.ordered
    @preloaded_books = preloaded_books_from_params
  end

  def create
    @report            = Report.new(report_params)
    @report.created_by = Current.user

    if @report.save
      sync_client_types(@report)
      sync_books(@report)
      @report.regenerate!
      redirect_to report_path(@report), notice: "Report created."
    else
      @client_types    = ClientType.ordered
      @preloaded_books = []
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @client_types = ClientType.ordered
  end

  def update
    if @report.update(report_params)
      sync_client_types(@report)
      sync_books(@report)
      @report.regenerate!
      redirect_to report_path(@report), notice: "Report updated."
    else
      @client_types = ClientType.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @report.destroy
    redirect_to reports_path, notice: "Report deleted."
  end

  # GET /reports/:id/render — print-friendly rendered HTML
  def render_html
    render layout: "report_print"
  end

  # GET /reports/:id/edit_display
  def edit_display
  end

  # PATCH /reports/:id/update_display
  def update_display
    @report.update!(rendered_content: params[:rendered_content])
    redirect_to report_path(@report), notice: "Report display updated."
  end

  # POST /reports/:id/reset_display
  def reset_display
    @report.regenerate!
    redirect_to report_path(@report), notice: "Report display reset to default."
  end

  # PATCH /reports/:id/reorder
  def reorder
    book_ids = Array(params[:book_ids]).map(&:to_i)
    book_ids.each_with_index do |book_id, index|
      @report.report_books.find_by(book_id: book_id)&.update_column(:position, index)
    end
    head :ok
  end

  private

  def set_report
    @report = accessible_reports.find(params[:id])
  end

  def accessible_reports
    if Current.user.hierarchy_level >= 50
      Report.all
    else
      user_ct_ids = Current.user.client_type_ids
      return Report.none if user_ct_ids.empty?

      Report.joins(:report_client_types)
            .where(report_client_types: { client_type_id: user_ct_ids })
            .distinct
    end
  end

  def report_params
    params.require(:report).permit(:title, :body, :footer, :report_type, :report_date, :sent, :pinned)
  end

  def sync_client_types(report)
    ids = Array(params.dig(:report, :client_type_ids)).map(&:to_i).select(&:positive?)
    report.report_client_types.destroy_all
    ids.each { |id| report.report_client_types.create!(client_type_id: id) }
  end

  def sync_books(report)
    ids = Array(params.dig(:report, :book_ids)).map(&:to_i).select(&:positive?)
    report.report_books.destroy_all
    ids.each_with_index { |id, i| report.report_books.create!(book_id: id, position: i) }
  end

  def preloaded_books_from_params
    return [] if params[:book_ids].blank?
    Book.kept.where(id: Array(params[:book_ids]))
  end
end
