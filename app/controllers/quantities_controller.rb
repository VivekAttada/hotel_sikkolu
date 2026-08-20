class QuantitiesController < ApplicationController
  def import
    if params[:file].blank?
      redirect_to root_path(tab: "quantity"), alert: "Please select an Excel file to upload."
      return
    end

    date = parse_date(params[:inventory_date]) || Date.current
    inventory = DailyInventory.import_from_spreadsheet(params[:file], date: date)

    redirect_to root_path(tab: "quantity", inventory_date: inventory.inventory_date),
                notice: "Imported #{inventory.inventory_items.count} items for #{inventory.inventory_date.strftime('%d %b %Y')}."
  rescue StandardError => e
    redirect_to root_path(tab: "quantity"), alert: "Import failed: #{e.message}"
  end

  def sample
    data, filename = XlsxExporter.quantity_sample_template
    send_data data,
      filename: filename,
      type: XlsxExporter::MIME_TYPE,
      disposition: "attachment"
  end

  def add_expense
    item = InventoryItem.find(params[:inventory_item_id])
    quantity_used = params[:quantity_used]
    notes = params[:notes]

    item.record_expense!(quantity_used, notes: notes)

    redirect_to root_path(
      tab: "quantity",
      inventory_date: item.daily_inventory.inventory_date,
      item_q: params[:item_q],
      unit: params[:unit],
      stock: params[:stock]
    ), notice: "Recorded expense of #{quantity_used} #{item.unit} for #{item.item_name}."
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path(tab: "quantity"), alert: "Inventory item not found."
  rescue ArgumentError => e
    redirect_to root_path(tab: "quantity", inventory_date: params[:inventory_date]),
                alert: e.message
  end

  private

  def parse_date(value)
    return if value.blank?

    Date.parse(value)
  rescue ArgumentError
    nil
  end
end
