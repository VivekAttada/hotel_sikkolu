class DashboardController < ApplicationController
  before_action :redirect_legacy_tab_param

  def grocery
    @active_tab = "grocery"
    load_grocery_data
    render :index
  end

  def checklist
    @active_tab = "checklist"
    load_checklist_data
    render :index
  end

  def bills
    @active_tab = "bills"
    load_bills_data
    render :index
  end

  private

  def redirect_legacy_tab_param
    tab = params[:tab].to_s
    return if tab.blank?

    query = request.query_parameters.except("tab")
    path = case tab
    when "checklist"
      checklist_path(query)
    when "bills", "deleted_bills"
      bills_path(query)
    when "grocery", "hotel_info", "quantity"
      grocery_path(query.except("tab"))
    else
      grocery_path
    end

    redirect_to path, status: :moved_permanently
  end

  def load_grocery_data
    @grocery_q = params[:grocery_q].to_s.strip
    @grocery_items = GroceryItem.recent_first
    @grocery_items = @grocery_items.where("LOWER(item_name) LIKE ?", "%#{@grocery_q.downcase}%") if @grocery_q.present?
    @grocery_has_items = GroceryItem.exists?
    @last_grocery_import = GroceryItem.maximum(:imported_at)
    @editing_grocery = GroceryItem.find_by(id: params[:edit_grocery]) if params[:edit_grocery].present?
    @new_grocery_item = GroceryItem.new
  end

  def load_checklist_data
    @checklist_date = parse_date(params[:checklist_date]) || Date.current
    @checklist_date = Date.current if @checklist_date > Date.current
    @checklist_view = params[:checklist_view].presence
    @checklist_view = "all" unless %w[all pending].include?(@checklist_view)
    @daily_checklist = DailyChecklist.ensure_entries_for(@checklist_date)
    @checklist_entries = @daily_checklist.checklist_entries
      .joins(:checklist_task)
      .merge(ChecklistTask.active_tasks)
      .includes(:checklist_task)
      .with_attached_photo
      .order(Arel.sql("CASE checklist_tasks.frequency WHEN 'daily' THEN 1 WHEN 'weekly' THEN 2 WHEN 'monthly' THEN 3 END"), "checklist_tasks.position ASC", "checklist_tasks.id ASC")
    @pending_checklist_entries = @checklist_entries.reject(&:checked)
    @checklist_entries_by_frequency = @checklist_entries.group_by { |entry| entry.checklist_task.frequency }
    @pending_entries_by_frequency = @pending_checklist_entries.group_by { |entry| entry.checklist_task.frequency }
    @checklist_done_count = @checklist_entries.count(&:checked)
    @checklist_pending_count = @pending_checklist_entries.size
  end

  def load_bills_data
    @dining_tables = DiningTable.ordered.includes(:bills)
    @bill_date = parse_date(params[:bill_date]) || Date.current
    @day_bills = Bill.for_day(@bill_date).includes(:dining_table, :bill_line_items).recent_first
    @day_bills_sum = @day_bills.sum(:subtotal)
    @deleted_bills = Bill.deleted_on(@bill_date).includes(:dining_table, :bill_line_items).recently_deleted
  end
end
