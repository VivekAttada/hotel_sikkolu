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

  def quantities
    @active_tab = "quantity"
    load_quantity_data
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
    when "quantity"
      quantities_path(query)
    when "bills", "deleted_bills"
      bills_path(query)
    when "grocery", "hotel_info"
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
      .order(Arel.sql("CASE checklist_tasks.frequency WHEN 'daily' THEN 1 WHEN 'weekly' THEN 2 WHEN 'monthly' THEN 3 END"), "checklist_tasks.position ASC", "checklist_tasks.id ASC")
    @pending_checklist_entries = @checklist_entries.reject(&:checked)
    @checklist_entries_by_frequency = @checklist_entries.group_by { |entry| entry.checklist_task.frequency }
    @pending_entries_by_frequency = @pending_checklist_entries.group_by { |entry| entry.checklist_task.frequency }
    @checklist_done_count = @checklist_entries.count(&:checked)
    @checklist_pending_count = @pending_checklist_entries.size
  end

  def load_quantity_data
    @inventory_date = parse_date(params[:inventory_date]) || Date.current
    @daily_inventory = DailyInventory.for_date(@inventory_date)
    @quantity_item_q = params[:item_q].to_s.strip
    @quantity_unit = params[:unit].to_s.strip
    @quantity_stock = params[:stock].to_s.strip
    @quantity_units = if @daily_inventory
      @daily_inventory.inventory_items.where.not(unit: [ nil, "" ]).distinct.order(:unit).pluck(:unit)
    else
      []
    end
    @inventory_items = filtered_inventory_items
    @recent_expenses = if @daily_inventory
      QuantityExpense.joins(:inventory_item)
        .where(inventory_items: { daily_inventory_id: @daily_inventory.id })
        .order(created_at: :desc)
        .limit(20)
    else
      QuantityExpense.none
    end
  end

  def load_bills_data
    @dining_tables = DiningTable.ordered.includes(:bills)
    @bill_date = parse_date(params[:bill_date]) || Date.current
    @day_bills = Bill.for_day(@bill_date).includes(:dining_table, :bill_line_items).recent_first
    @day_bills_sum = @day_bills.sum(:subtotal)
    @deleted_bills = Bill.deleted_on(@bill_date).includes(:dining_table, :bill_line_items).recently_deleted
  end

  def filtered_inventory_items
    return InventoryItem.none unless @daily_inventory

    items = @daily_inventory.inventory_items.order(:item_name)

    if @quantity_item_q.present?
      items = items.where("LOWER(item_name) LIKE ?", "%#{@quantity_item_q.downcase}%")
    end

    items = items.where(unit: @quantity_unit) if @quantity_unit.present?

    case @quantity_stock
    when "in_stock"
      items = items.where("current_quantity > 0")
    when "low"
      items = items.where("current_quantity > 0 AND current_quantity <= (opening_quantity * 0.2)")
    when "out"
      items = items.where(current_quantity: 0)
    end

    items
  end
end
