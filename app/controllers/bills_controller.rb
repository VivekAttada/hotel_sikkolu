class BillsController < ApplicationController
  before_action :set_dining_table, only: [ :show, :add_item ]
  before_action :set_bill_from_table, only: [ :add_item ]
  before_action :set_bill, only: [ :update_item, :remove_item, :pay, :pdf, :destroy ]

  def show
    @bill = Bill.open_for!(@dining_table)
    @menu_items_by_category = MenuItem.by_category
    @menu_categories = @menu_items_by_category.keys
    @selected_menu_category = params[:menu_category].presence
    @selected_menu_category = @menu_categories.first if @selected_menu_category.blank? || @menu_categories.exclude?(@selected_menu_category)
    @line_items = @bill.bill_line_items.includes(:menu_item).order(:id)
  end

  def add_item
    menu_item = MenuItem.available.find(params[:menu_item_id])
    quantity = params[:quantity].presence || 1
    @bill.add_menu_item!(menu_item, quantity: quantity)
    redirect_to bill_path(@dining_table, menu_category: params[:menu_category].presence),
                notice: "Added #{menu_item.name} to table #{@dining_table.name}."
  rescue ActiveRecord::RecordNotFound
    redirect_to bill_path(@dining_table, menu_category: params[:menu_category].presence), alert: "Menu item not found."
  rescue ArgumentError => e
    redirect_to bill_path(@dining_table, menu_category: params[:menu_category].presence), alert: e.message
  end

  def update_item
    raise ArgumentError, "Bill is deleted" if @bill.deleted?

    line = @bill.bill_line_items.find(params[:line_item_id])
    @bill.update_line_quantity!(line, params[:quantity])
    redirect_to bill_path(@bill.dining_table, menu_category: params[:menu_category].presence), notice: "Updated #{line.item_name}."
  rescue ActiveRecord::RecordNotFound
    redirect_to bills_path, alert: "Line item not found."
  rescue ArgumentError => e
    redirect_to bill_path(@bill.dining_table, menu_category: params[:menu_category].presence), alert: e.message
  end

  def remove_item
    raise ArgumentError, "Bill is deleted" if @bill.deleted?

    line = @bill.bill_line_items.find(params[:line_item_id])
    name = line.item_name
    @bill.remove_line_item!(line)
    redirect_to bill_path(@bill.dining_table, menu_category: params[:menu_category].presence), notice: "Removed #{name}."
  rescue ActiveRecord::RecordNotFound
    redirect_to bills_path, alert: "Line item not found."
  rescue ArgumentError => e
    redirect_to bill_path(@bill.dining_table, menu_category: params[:menu_category].presence), alert: e.message
  end

  def pay
    @bill.mark_paid!
    redirect_to bill_pdf_path(@bill), notice: "Bill #{@bill.bill_number} marked as paid."
  rescue ArgumentError => e
    redirect_to bill_path(@bill.dining_table), alert: e.message
  end

  def destroy
    table_name = @bill.dining_table.name
    bill_number = @bill.bill_number
    @bill.soft_delete!
    redirect_to bills_path(bill_date: Date.current), notice: "Bill #{bill_number} (table #{table_name}) moved to Deleted Bills."
  rescue ArgumentError => e
    redirect_to bills_path, alert: e.message
  end

  def pdf
    unless @bill.status == "paid"
      redirect_back_or_bills(alert: "PDF is available after payment.")
      return
    end

    send_data BillPdf.generate(@bill),
      filename: "bill_#{@bill.bill_number}.pdf",
      type: "application/pdf",
      disposition: "inline"
  end

  private

  def set_dining_table
    @dining_table = DiningTable.ordered.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to bills_path, alert: "Dining table not found."
  end

  def set_bill_from_table
    return if performed?

    @bill = @dining_table.active_bill || Bill.open_for!(@dining_table)
  end

  def set_bill
    @bill = Bill.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to bills_path, alert: "Bill not found."
  end

  def redirect_back_or_bills(alert:)
    if @bill&.deleted?
      redirect_to bills_path(bill_date: @bill.deleted_at&.to_date || Date.current), alert: alert
    elsif @bill
      redirect_to bill_path(@bill.dining_table), alert: alert
    else
      redirect_to bills_path, alert: alert
    end
  end
end
