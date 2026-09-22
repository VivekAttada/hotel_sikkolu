class BillsController < ApplicationController
  before_action :require_bill_access!
  before_action :set_dining_table, only: [ :show, :add_item ]
  before_action :set_bill_from_table, only: [ :add_item ]
  before_action :set_bill, only: [ :update_item, :remove_item, :pay, :pdf, :print, :kot, :destroy, :void, :restore, :guest ]
  before_action :require_receipt_access!, only: [ :pdf, :print ]
  before_action :require_takeaway_for_takeaway_bill!, only: [ :add_item, :update_item, :remove_item, :pay, :kot, :destroy, :guest ]

  def show
    if @dining_table.takeaway?
      if current_user.can_access_tab?(:takeaway)
        redirect_to takeaway_path(menu_category: params[:menu_category].presence, bill_id: params[:bill_id].presence)
      else
        redirect_to bills_path, alert: "You don't have access to takeaway orders."
      end
      return
    end

    @bill = Bill.open_for!(@dining_table, user: current_user)
    load_order_screen
  end

  def add_item
    menu_item = MenuItem.available.find(params[:menu_item_id])
    quantity = params[:quantity].presence || 1
    @bill.add_menu_item!(menu_item, quantity: quantity, note: params[:note])
    redirect_to order_return_path(@dining_table, menu_category: params[:menu_category].presence, bill_id: @bill.id),
                notice: "Added #{menu_item.name}."
  rescue ActiveRecord::RecordNotFound
    redirect_to order_return_path(@dining_table, menu_category: params[:menu_category].presence, bill_id: params[:bill_id].presence), alert: "Menu item not found."
  rescue ArgumentError => e
    redirect_to order_return_path(@dining_table, menu_category: params[:menu_category].presence, bill_id: @bill&.id || params[:bill_id].presence), alert: e.message
  end

  def update_item
    raise ArgumentError, "Bill is cancelled" if @bill.deleted?

    line = @bill.bill_line_items.find(params[:line_item_id])
    name = line.item_name

    if params.key?(:note) && !params.key?(:quantity)
      @bill.update_line_note!(line, params[:note])
      redirect_to order_return_path(@bill.dining_table, menu_category: params[:menu_category].presence, bill_id: @bill.id),
                  notice: "Updated note for #{name}."
      return
    end

    @bill.update_line_quantity!(line, params[:quantity])
    redirect_to order_return_path(@bill.dining_table, menu_category: params[:menu_category].presence, bill_id: @bill.id), notice: "Updated #{name}."
  rescue ActiveRecord::RecordNotFound
    redirect_to bills_path, alert: "Line item not found."
  rescue ArgumentError => e
    redirect_to order_return_path(@bill.dining_table, menu_category: params[:menu_category].presence, bill_id: @bill.id), alert: e.message
  end

  def remove_item
    raise ArgumentError, "Bill is cancelled" if @bill.deleted?

    line = @bill.bill_line_items.find(params[:line_item_id])
    name = line.item_name
    @bill.remove_line_item!(line)
    redirect_to order_return_path(@bill.dining_table, menu_category: params[:menu_category].presence, bill_id: @bill.id), notice: "Removed #{name}."
  rescue ActiveRecord::RecordNotFound
    redirect_to bills_path, alert: "Line item not found."
  rescue ArgumentError => e
    redirect_to order_return_path(@bill.dining_table, menu_category: params[:menu_category].presence, bill_id: @bill.id), alert: e.message
  end

  def guest
    @bill.save_guest!(name: params[:guest_name], phone: params[:guest_phone], user: current_user)
    redirect_to order_return_path(@bill.dining_table, bill_id: @bill.id), notice: "Guest details saved."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to order_return_path(@bill.dining_table, bill_id: @bill.id), alert: e.record.errors.full_messages.to_sentence
  end

  def pay
    table = @bill.dining_table
    @bill.mark_paid!(
      user: current_user,
      payment_method: params[:payment_method],
      cash_amount: params[:cash_amount],
      upi_amount: params[:upi_amount],
      card_amount: params[:card_amount],
      discount_amount: params[:discount_amount],
      discount_percent: params[:discount_percent],
      discount_reason: params[:discount_reason],
      complementary: params[:complementary],
      guest_name: params[:guest_name],
      guest_phone: params[:guest_phone],
      removal_reason: params[:removal_reason],
      mark_due: params[:mark_due] == "1"
    )
    restored = table.collapse_split_if_settled! unless @bill.due?
    notice = if @bill.due?
      "Bill marked due. Balance ₹ #{view_context.number_with_precision(@bill.balance_due, precision: 2)}."
    else
      "Settled and saved to today's sales."
    end
    notice += " #{restored.name} is one table again." if restored

    if table.takeaway?
      redirect_to takeaway_path, notice: notice
    else
      redirect_to bills_path, notice: notice
    end
  rescue ArgumentError => e
    redirect_to order_return_path(@bill.dining_table, bill_id: @bill.id), alert: e.message
  end

  def destroy
    table = @bill.dining_table
    bill_number = @bill.bill_number
    was_takeaway = table.takeaway?
    @bill.cancel!(user: current_user, reason: params[:cancel_reason])
    restored = table.collapse_split_if_settled!
    if was_takeaway
      redirect_to takeaway_path, notice: "Bill #{bill_number} cancelled."
    else
      notice = "Bill #{bill_number} (table #{table.name}) cancelled."
      notice += " #{restored.name} is one table again." if restored
      redirect_to bills_path, notice: notice
    end
  rescue ArgumentError => e
    redirect_to bills_path, alert: e.message
  end

  def void
    @bill.void!(user: current_user, reason: params[:void_reason])
    table = @bill.dining_table
    table.collapse_split_if_settled!
    redirect_back fallback_location: payments_path(payment_date: @bill.service_date), notice: "Bill #{@bill.bill_number} voided. It stays in the books."
  rescue ArgumentError => e
    redirect_back fallback_location: payments_path, alert: e.message
  end

  def restore
    @bill.restore_void!(user: current_user)
    redirect_back fallback_location: payments_path(payment_date: @bill.service_date), notice: "Bill #{@bill.bill_number} restored to collection."
  rescue ArgumentError => e
    redirect_back fallback_location: payments_path, alert: e.message
  end

  def pdf
    unless @bill.status == "paid" && !@bill.voided? && !@bill.deleted?
      redirect_back_or_bills(alert: "PDF is available after payment.")
      return
    end

    send_data BillPdf.generate(@bill),
      filename: "bill_#{@bill.bill_number}.pdf",
      type: "application/pdf",
      disposition: "inline"
  end

  def print
    if @bill.deleted? || @bill.bill_line_items.empty?
      redirect_back_or_bills(alert: "Print is available after items are added.")
      return
    end

    @line_items = @bill.bill_line_items.includes(:menu_item).order(:id)
    @bill_removals = @bill.bill_removals.recent_first
    render layout: "print"
  end

  def kot
    if @bill.deleted? || @bill.voided?
      redirect_back_or_bills(alert: "Cannot print KOT for a cancelled bill.")
      return
    end

    @line_items = @bill.bill_line_items.includes(:menu_item).order(:id)
    if @line_items.empty?
      redirect_to order_return_path(@bill.dining_table, bill_id: @bill.id), alert: "Add items to the order before printing KOT."
      return
    end

    @kot_additional = @bill.kot_sent?

    @kot_rows = @line_items.filter_map do |line|
      qty = line.pending_kot_quantity
      next if qty <= 0

      kot_row_for(line, qty)
    end

    if @kot_rows.empty?
      redirect_to order_return_path(@bill.dining_table, bill_id: @bill.id),
                  alert: "All items already sent to kitchen. Add a new item to print another KOT."
      return
    end

    @kot_reprint = false
    Bill.transaction do
      @kitchen_ticket = @bill.issue_kot!
      @bill.mark_kot_sent!
    end
    @kot_number = @kitchen_ticket.kot_number

    render layout: "print"
  end

  private

  def require_receipt_access!
    return if performed?
    return if current_user.admin? || current_user.manager?
    return if @bill&.open_on_table?
    return if @bill&.paid_by_id == current_user.id
    return if @bill&.opened_by_id == current_user.id && @bill&.paid?

    redirect_to bills_path, alert: "Detailed bills are only available to admin and manager."
  end

  def require_takeaway_for_takeaway_bill!
    return if performed?

    table = @dining_table || @bill&.dining_table
    return unless table&.takeaway?

    require_takeaway_access!
  end

  def load_order_screen
    @menu_items_by_category = MenuItem.by_category
    @menu_categories = @menu_items_by_category.keys
    @selected_menu_category = params[:menu_category].presence
    @selected_menu_category = @menu_categories.first if @selected_menu_category.blank? || @menu_categories.exclude?(@selected_menu_category)
    @line_items = @bill.bill_line_items.includes(:menu_item).order(:id)
    @bill_removals = @bill.bill_removals.recent_first
  end

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
      unless current_user.can_access_tab?(:takeaway)
        redirect_to bills_path, alert: "You don't have access to takeaway orders."
        return
      end

      @bill = @dining_table.bills.open_on_table.find_by(id: params[:bill_id])
      unless @bill
        redirect_to takeaway_path, alert: "Select a takeaway order first."
      end
    else
      @bill = @dining_table.active_bill || Bill.open_for!(@dining_table, user: current_user)
    end
  end

  def set_bill
    @bill = Bill.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to bills_path, alert: "Bill not found."
  end

  def order_return_path(dining_table, **opts)
    path = if dining_table.takeaway?
      takeaway_path({ bill_id: opts[:bill_id] || @bill&.id, menu_category: opts[:menu_category] }.compact)
    else
      bill_path(dining_table, { menu_category: opts[:menu_category] }.compact)
    end

    category = opts[:menu_category]
    return path if category.blank?

    "#{path}##{view_context.menu_category_dom_id(category)}"
  end

  def kot_row_for(line, quantity)
    {
      name: line.item_name,
      quantity: quantity,
      category: line.menu_item&.category,
      note: line.note
    }
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
