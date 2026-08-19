class GroceriesController < ApplicationController
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
end
