class ExportsController < ApplicationController
  def grocery
    items = GroceryItem.recent_first
    return redirect_with_alert("grocery", "No grocery data to export.") if items.none?

    data, filename = XlsxExporter.grocery_items(items)
    send_xlsx(data, filename)
  end

  def checklist
    date = parse_date(params[:checklist_date]) || Date.current
    date = Date.current if date > Date.current
    daily_checklist = DailyChecklist.ensure_entries_for(date)
    entries = checklist_entries_for(daily_checklist)
    return redirect_with_alert("checklist", "No checklist data to export.", checklist_date: date) if entries.none?

    data, filename = XlsxExporter.checklist(daily_checklist, entries)
    send_xlsx(data, filename)
  end

  def quantities
    date = parse_date(params[:inventory_date]) || Date.current
    daily_inventory = DailyInventory.for_date(date)
    return redirect_with_alert("quantity", "No inventory data to export for this date.", inventory_date: date) unless daily_inventory

    inventory_items = daily_inventory.inventory_items.order(:item_name)
    expenses = QuantityExpense.joins(:inventory_item)
      .where(inventory_items: { daily_inventory_id: daily_inventory.id })
      .order(created_at: :desc)

    data, filename = XlsxExporter.quantities(daily_inventory, inventory_items, expenses)
    send_xlsx(data, filename)
  end

  private
  def send_xlsx(data, filename)
    send_data data,
      filename: filename,
      type: XlsxExporter::MIME_TYPE,
      disposition: "attachment"
  end

  def redirect_with_alert(tab, message, extra_params = {})
    path = case tab
    when "checklist" then checklist_path(extra_params)
    when "quantity" then quantities_path(extra_params)
    when "bills" then bills_path(extra_params)
    else grocery_path(extra_params)
    end
    redirect_to path, alert: message
  end

  def checklist_entries_for(daily_checklist)
    daily_checklist.checklist_entries
      .joins(:checklist_task)
      .merge(ChecklistTask.active_tasks)
      .includes(:checklist_task)
      .order(Arel.sql("CASE checklist_tasks.frequency WHEN 'daily' THEN 1 WHEN 'weekly' THEN 2 WHEN 'monthly' THEN 3 END"), "checklist_tasks.position ASC", "checklist_tasks.id ASC")
  end
end
