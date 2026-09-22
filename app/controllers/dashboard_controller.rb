class DashboardController < ApplicationController
  before_action :redirect_legacy_tab_param
  before_action :authorize_dashboard_tab, except: :home

  def home
    redirect_to signed_in_home_path
  end

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

  def paid_bills
    @active_tab = "paid_bills"
    load_paid_bills_data
    render :index
  end

  def bill_edits
    @active_tab = "bill_edits"
    load_bill_edits_data
    render :index
  end

  def cancelled_kots
    @active_tab = "cancelled_kots"
    load_cancelled_kots_data
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

  def authorize_dashboard_tab
    return if current_user.can_access_tab?(action_name)

    redirect_to signed_in_home_path, alert: "You don't have access to that page."
  end

  def redirect_legacy_tab_param
    tab = params[:tab].to_s
    return if tab.blank?

    query = request.query_parameters.except("tab")
    path = case tab
    when "checklist"
      checklist_path(query)
    when "bills", "deleted_bills"
      bills_path(query)
    when "paid_bills"
      paid_bills_path(query)
    when "bill_edits"
      bill_edits_path(query)
    when "cancelled_kots"
      cancelled_kots_path(query)
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
    @grocery_has_items = GroceryItem.current.exists?
    @last_grocery_import = GroceryImport.recent_first.first&.imported_at || GroceryItem.current.maximum(:imported_at)
    @grocery_import_count = GroceryImport.count
    @editing_grocery = GroceryItem.current.find_by(id: params[:edit_grocery]) if params[:edit_grocery].present?
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
    @bill_date = Bill.business_date_for
    return unless current_user.can_view_paid_bills?

    @due_bills = Bill.due_on(@bill_date).includes(:dining_table, :bill_line_items).recent_first
    return unless current_user.admin?

    @voided_bills = Bill.voided_on(@bill_date).includes(:dining_table, :bill_line_items, :voided_by).order(voided_at: :desc)
    @deleted_bills = Bill.deleted_on(@bill_date).includes(:dining_table, :bill_line_items, :cancelled_by).recently_deleted
  end

  def load_paid_bills_data
    @bill_date = parse_date(params[:bill_date]) || Bill.business_date_for
    @day_bills = Bill.for_day(@bill_date).includes(:dining_table, :bill_line_items, :paid_by, :opened_by).recent_first
    @due_bills = Bill.due_on(@bill_date).includes(:dining_table, :bill_line_items, :paid_by, :opened_by).recent_first
  end

  def load_bill_edits_data
    @edit_date = parse_date(params[:edit_date]) || Bill.business_date_for
    @bill_edits = BillEdit.for_day(@edit_date).includes(:user, bill: :dining_table).recent_first
  end

  def load_cancelled_kots_data
    @cancelled_kot_date = parse_date(params[:kot_date]) || Bill.business_date_for
    @cancelled_kots = BillRemoval.for_business_date(@cancelled_kot_date).includes(:removed_by, bill: [ :dining_table, :opened_by, :paid_by ]).recent_first
  end

  def load_payments_data
    @payment_date = parse_date(params[:payment_date]) || Bill.business_date_for
    @day_bills = Bill.for_day(@payment_date).includes(:dining_table, :bill_line_items, :paid_by, :opened_by).recent_first
    @due_bills = Bill.due_on(@payment_date).includes(:dining_table, :bill_line_items).recent_first
    @voided_bills = Bill.voided_on(@payment_date).includes(:dining_table, :bill_line_items, :voided_by).order(voided_at: :desc)
    @deleted_bills = Bill.deleted_on(@payment_date).includes(:dining_table, :bill_line_items, :cancelled_by).recently_deleted

    @day_bills_sum = @day_bills.sum(:total)
    @day_cash_sum = @day_bills.sum(:cash_amount)
    @day_upi_sum = @day_bills.sum(:upi_amount)
    @day_card_sum = @day_bills.sum(:card_amount)
    @day_nc_sum = @day_bills.where(complementary: true).count
    @day_due_sum = @due_bills.sum(:total)
    @day_void_sum = @voided_bills.sum(:total)
    @day_cash_count = @day_bills.where("cash_amount > 0").count
    @day_upi_count = @day_bills.where("upi_amount > 0").count
    @day_card_count = @day_bills.where("card_amount > 0").count

    takeaway = DiningTable.find_by(name: DiningTable::TAKEAWAY_NAME)
    @day_takeaway_sum = takeaway ? @day_bills.where(dining_table_id: takeaway.id).sum(:total) : 0
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
    @report_date = Bill.business_date_for
    @daily_report_body = DailyReport.body(@report_date)
    @resend_configured = ResendDailyReport.configured?
  end
end
