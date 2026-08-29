class BillsController < ApplicationController
  before_action :set_dining_table, only: [ :show, :add_item ]
  before_action :set_bill_from_table, only: [ :add_item ]
  before_action :set_bill, only: [ :update_item, :remove_item, :pay, :pdf, :print, :kot, :destroy ]

  def show
    if @dining_table.takeaway?
      redirect_to takeaway_path(menu_category: params[:menu_category].presence, bill_id: params[:bill_id].presence)
      return
    end

    @bill = Bill.open_for!(@dining_table)
    @menu_items_by_category = MenuItem.by_category
    @menu_categories = @menu_items_by_category.keys
    @selected_menu_category = params[:menu_category].presence
    @selected_menu_category = @menu_categories.first if @selected_menu_category.blank? || @menu_categories.exclude?(@selected_menu_category)
    @line_items = @bill.bill_line_items.includes(:menu_item).order(:id)
    @bill_removals = @bill.bill_removals.recent_first
  end

  def add_item
    menu_item = MenuItem.available.find(params[:menu_item_id])
    quantity = params[:quantity].presence || 1
    @bill.add_menu_item!(menu_item, quantity: quantity)
    redirect_to order_return_path(@dining_table, menu_category: params[:menu_category].presence, bill_id: @bill.id),
                notice: "Added #{menu_item.name}."
  rescue ActiveRecord::RecordNotFound
    redirect_to order_return_path(@dining_table, menu_category: params[:menu_category].presence, bill_id: params[:bill_id].presence), alert: "Menu item not found."
  rescue ArgumentError => e
    redirect_to order_return_path(@dining_table, menu_category: params[:menu_category].presence, bill_id: @bill&.id || params[:bill_id].presence), alert: e.message
  end

  def update_item
    raise ArgumentError, "Bill is deleted" if @bill.deleted?

    line = @bill.bill_line_items.find(params[:line_item_id])
    @bill.update_line_quantity!(line, params[:quantity])
    redirect_to order_return_path(@bill.dining_table, menu_category: params[:menu_category].presence, bill_id: @bill.id), notice: "Updated #{line.item_name}."
  rescue ActiveRecord::RecordNotFound
    redirect_to bills_path, alert: "Line item not found."
  rescue ArgumentError => e
    redirect_to order_return_path(@bill.dining_table, menu_category: params[:menu_category].presence, bill_id: @bill.id), alert: e.message
  end

  def remove_item
    raise ArgumentError, "Bill is deleted" if @bill.deleted?

    line = @bill.bill_line_items.find(params[:line_item_id])
    name = line.item_name
    @bill.remove_line_item!(line)
    redirect_to order_return_path(@bill.dining_table, menu_category: params[:menu_category].presence, bill_id: @bill.id), notice: "Removed #{name}."
  rescue ActiveRecord::RecordNotFound
    redirect_to bills_path, alert: "Line item not found."
  rescue ArgumentError => e
    redirect_to order_return_path(@bill.dining_table, menu_category: params[:menu_category].presence, bill_id: @bill.id), alert: e.message
  end

  def pay
    @bill.mark_paid!(
      payment_method: params[:payment_method],
      removal_reason: params[:removal_reason]
    )
    redirect_to bill_pdf_path(@bill),
                notice: "Bill #{@bill.bill_number} settled via #{@bill.payment_method_label}."
  rescue ArgumentError => e
    redirect_to order_return_path(@bill.dining_table, bill_id: @bill.id), alert: e.message
  end

  def destroy
    table = @bill.dining_table
    bill_number = @bill.bill_number
    was_takeaway = table.takeaway?
    @bill.soft_delete!
    if was_takeaway
      redirect_to takeaway_path, notice: "Bill #{bill_number} moved to Deleted Bills."
    else
      redirect_to bills_path(bill_date: Date.current), notice: "Bill #{bill_number} (table #{table.name}) moved to Deleted Bills."
    end
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

  def print
    unless @bill.status == "paid"
      redirect_back_or_bills(alert: "Print is available after payment.")
      return
    end

    @line_items = @bill.bill_line_items.includes(:menu_item).order(:id)
    @bill_removals = @bill.bill_removals.recent_first
    render layout: "print"
  end

  def kot
    if @bill.deleted?
      redirect_back_or_bills(alert: "Cannot print KOT for a deleted bill.")
      return
    end

    @line_items = @bill.bill_line_items.includes(:menu_item).order(:id)
    if @line_items.empty?
      redirect_to order_return_path(@bill.dining_table, bill_id: @bill.id), alert: "Add items to the order before printing KOT."
      return
    end

    reprint = params[:reprint].present?

    @kot_rows = if reprint
      @line_items.map { |line| { name: line.item_name, quantity: line.quantity, category: line.menu_item&.category } }
    else
      @line_items.filter_map do |line|
        qty = line.pending_kot_quantity
        next if qty <= 0

        { name: line.item_name, quantity: qty, category: line.menu_item&.category }
      end
    end

    if @kot_rows.empty?
      redirect_to order_return_path(@bill.dining_table, bill_id: @bill.id),
                  alert: "All items already sent to kitchen. Use Reprint KOT for a full copy."
      return
    end

    @kot_reprint = reprint
    @bill.mark_kot_sent! unless reprint

    render layout: "print"
  end

  private

  def set_dining_table
    @dining_table = DiningTable.find(params[:id])
    unless @dining_table.active? || @dining_table.takeaway?
      redirect_to bills_path, alert: "Dining table not found."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to bills_path, alert: "Dining table not found."
  end

  def set_bill_from_table
    return if performed?

    if @dining_table.takeaway?
      @bill = @dining_table.bills.active.find_by(id: params[:bill_id])
      unless @bill
        redirect_to takeaway_path, alert: "Select a takeaway order first."
      end
    else
      @bill = @dining_table.active_bill || Bill.open_for!(@dining_table)
    end
  end

  def set_bill
    @bill = Bill.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to bills_path, alert: "Bill not found."
  end

  def order_return_path(dining_table, **opts)
    if dining_table.takeaway?
      takeaway_path({ bill_id: opts[:bill_id] || @bill&.id, menu_category: opts[:menu_category] }.compact)
    else
      bill_path(dining_table, { menu_category: opts[:menu_category] }.compact)
    end
  end

  def redirect_back_or_bills(alert:)
    if @bill&.deleted?
      redirect_to bills_path(bill_date: @bill.deleted_at&.to_date || Date.current), alert: alert
    elsif @bill
      redirect_to order_return_path(@bill.dining_table, bill_id: @bill.id), alert: alert
    else
      redirect_to bills_path, alert: alert
    end
  end
end
