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

  def payments
    @active_tab = "payments"
    load_payments_data
    render :index
  end

  def settings
    @active_tab = "settings"
    load_settings_data
    render :index
  end

  def takeaway
    @active_tab = "takeaway"
    load_takeaway_data
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
    when "payments"
      payments_path(query)
    when "settings"
      settings_path(query)
    when "takeaway"
      takeaway_path(query)
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
    @dining_tables = DiningTable.ordered.includes(:bills, :parent_dining_table, :split_children)
    @bill_date = parse_date(params[:bill_date]) || Date.current
    @day_bills = Bill.for_day(@bill_date).includes(:dining_table, :bill_line_items).recent_first
    @deleted_bills = Bill.deleted_on(@bill_date).includes(:dining_table, :bill_line_items).recently_deleted
  end

  def load_payments_data
    @payment_date = parse_date(params[:payment_date]) || Date.current
    @day_bills = Bill.for_day(@payment_date).includes(:dining_table, :bill_line_items).recent_first
    @deleted_bills = Bill.deleted_on(@payment_date).includes(:dining_table, :bill_line_items).recently_deleted

    @day_bills_sum = @day_bills.sum(:subtotal)
    @day_cash_sum = @day_bills.where(payment_method: "cash").sum(:subtotal)
    @day_upi_sum = @day_bills.where(payment_method: "upi").sum(:subtotal)
    @day_card_sum = @day_bills.where(payment_method: "card").sum(:subtotal)
    @day_cash_count = @day_bills.where(payment_method: "cash").count
    @day_upi_count = @day_bills.where(payment_method: "upi").count
    @day_card_count = @day_bills.where(payment_method: "card").count

    takeaway = DiningTable.find_by(name: DiningTable::TAKEAWAY_NAME)
    @day_takeaway_sum = takeaway ? @day_bills.where(dining_table_id: takeaway.id).sum(:subtotal) : 0
    @day_takeaway_count = takeaway ? @day_bills.where(dining_table_id: takeaway.id).count : 0
    @day_dine_in_sum = @day_bills_sum - @day_takeaway_sum
    @day_dine_in_count = @day_bills.size - @day_takeaway_count

    @payment_method_rows = [
      { label: "Cash", amount: @day_cash_sum, count: @day_cash_count, tone: "gold" },
      { label: "UPI", amount: @day_upi_sum, count: @day_upi_count, tone: "cream" },
      { label: "Card", amount: @day_card_sum, count: @day_card_count, tone: "olive" }
    ]
    @channel_rows = [
      { label: "Dine-in", amount: @day_dine_in_sum, count: @day_dine_in_count, tone: "gold" },
      { label: "Take Away", amount: @day_takeaway_sum, count: @day_takeaway_count, tone: "cream" }
    ]
  end

  def load_takeaway_data
    @dining_table = DiningTable.takeaway!
    @active_takeaway_orders = Bill.active_takeaways.includes(:bill_line_items)

    if params[:bill_id].present?
      @bill = @active_takeaway_orders.find_by(id: params[:bill_id])
      @bill ||= @dining_table.bills.active.find_by(id: params[:bill_id])
    end

    return unless @bill

    @menu_items_by_category = MenuItem.by_category
    @menu_categories = @menu_items_by_category.keys
    @selected_menu_category = params[:menu_category].presence
    @selected_menu_category = @menu_categories.first if @selected_menu_category.blank? || @menu_categories.exclude?(@selected_menu_category)
    @line_items = @bill.bill_line_items.includes(:menu_item).order(:id)
    @bill_removals = @bill.bill_removals.recent_first
  end

  def load_settings_data
    @whatsapp_number = AppSetting.whatsapp_number
    @whatsapp_normalized = AppSetting.normalized_whatsapp_number
    @report_recipients = ResendDailyReport.recipients
    @report_date = Date.current
    @daily_report_body = DailyReport.body(@report_date)
    @resend_configured = ResendDailyReport.configured?
  end
end
