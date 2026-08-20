class GroceriesController < ApplicationController
  before_action :set_grocery_item, only: [ :update, :destroy ]

  def import
    if params[:file].blank?
      redirect_to root_path(tab: "grocery"), alert: "Please select an Excel file to upload."
      return
    end

    count = GroceryItem.import_from_spreadsheet(params[:file])
    redirect_to root_path(tab: "grocery"), notice: "Successfully imported #{count} grocery items."
  rescue StandardError => e
    redirect_to root_path(tab: "grocery"), alert: "Import failed: #{e.message}"
  end

  def sample
    data, filename = XlsxExporter.grocery_sample_template
    send_data data,
      filename: filename,
      type: XlsxExporter::MIME_TYPE,
      disposition: "attachment"
  end

  def create
    item = GroceryItem.new(grocery_params)
    item.imported_at ||= Time.current
    item.serial_no ||= next_serial_no
    item.apply_total_stock!

    if item.save
      redirect_to root_path(tab: "grocery"), notice: "Added #{item.item_name}."
    else
      redirect_to root_path(tab: "grocery"), alert: item.errors.full_messages.to_sentence
    end
  end

  def update
    @grocery_item.assign_attributes(grocery_params)
    @grocery_item.apply_total_stock!

    if @grocery_item.save
      redirect_to root_path(tab: "grocery"), notice: "Updated #{@grocery_item.item_name}."
    else
      redirect_to root_path(tab: "grocery", edit_grocery: @grocery_item.id),
                  alert: @grocery_item.errors.full_messages.to_sentence
    end
  end

  def destroy
    name = @grocery_item.item_name
    @grocery_item.destroy!
    redirect_to root_path(tab: "grocery"), notice: "Deleted #{name}."
  rescue ActiveRecord::RecordNotDestroyed
    redirect_to root_path(tab: "grocery"), alert: "Could not delete grocery item."
  end

  private

  def set_grocery_item
    @grocery_item = GroceryItem.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path(tab: "grocery"), alert: "Grocery item not found."
  end

  def grocery_params
    params.require(:grocery_item).permit(
      :serial_no,
      :item_name,
      :old_stock,
      :new_stock_added,
      :unit,
      :quantity
    )
  end

  def next_serial_no
    (GroceryItem.maximum(:serial_no) || 0) + 1
  end
end
