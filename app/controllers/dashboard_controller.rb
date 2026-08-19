class DashboardController < ApplicationController
  def index
    @active_tab = params[:tab] || "grocery"
    @grocery_items = GroceryItem.recent_first
    @last_grocery_import = GroceryItem.maximum(:imported_at)

    @checklist_date = parse_date(params[:checklist_date]) || Date.current
    @daily_checklist = DailyChecklist.ensure_entries_for(@checklist_date)
    @checklist_entries = @daily_checklist.checklist_entries
      .joins(:checklist_task)
      .merge(ChecklistTask.active_tasks)
      .includes(:checklist_task)
      .order(Arel.sql("CASE checklist_tasks.frequency WHEN 'daily' THEN 1 WHEN 'weekly' THEN 2 WHEN 'monthly' THEN 3 END"), "checklist_tasks.position ASC", "checklist_tasks.id ASC")
    @checklist_entries_by_frequency = @checklist_entries.group_by { |entry| entry.checklist_task.frequency }

    @inventory_date = parse_date(params[:inventory_date]) || Date.current
    @daily_inventory = DailyInventory.for_date(@inventory_date)
    @inventory_items = @daily_inventory&.inventory_items&.order(:item_name) || InventoryItem.none
    @recent_expenses = if @daily_inventory
      QuantityExpense.joins(:inventory_item)
        .where(inventory_items: { daily_inventory_id: @daily_inventory.id })
        .order(created_at: :desc)
        .limit(20)
    else
      QuantityExpense.none
    end

    @team_members = TeamMember.ordered
  end

  private

  def parse_date(value)
    return if value.blank?

    Date.parse(value)
  rescue ArgumentError
    nil
  end
end
