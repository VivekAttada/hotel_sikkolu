class DailyReport
  def self.body(date = Bill.business_date_for)
    new(date).body
  end

  def self.whatsapp_url(date: Bill.business_date_for, phone: nil)
    phone = AppSetting.normalized_whatsapp_number(phone.presence || AppSetting.whatsapp_number)
    return nil if phone.blank?

    "https://wa.me/#{phone}?text=#{ERB::Util.url_encode(body(date))}"
  end

  def initialize(date = Bill.business_date_for)
    @date = date
    @bills = Bill.for_day(@date).includes(:dining_table, :bill_line_items, :paid_by, :opened_by).recent_first
    @due = Bill.due_on(@date)
    @voided = Bill.voided_on(@date)
    @deleted = Bill.deleted_on(@date)
  end

  def body
    total = @bills.sum(:total)
    cash = @bills.sum(:cash_amount)
    upi = @bills.sum(:upi_amount)
    card = @bills.sum(:card_amount)

    takeaway_id = DiningTable.find_by(name: DiningTable::TAKEAWAY_NAME)&.id
    takeaway_sum = takeaway_id ? @bills.where(dining_table_id: takeaway_id).sum(:total) : 0
    dine_in_sum = total - takeaway_sum
    takeaway_count = takeaway_id ? @bills.where(dining_table_id: takeaway_id).count : 0
    dine_in_count = @bills.size - takeaway_count

    lines = [
      "Hotel Sikkolu — Daily Report",
      "Date: #{@date.strftime('%d %b %Y')} (business day, 6am cutoff)",
      "",
      "TOTAL COLLECTION: Rs. #{money(total)}",
      "Paid bills: #{@bills.size}",
      "Due bills: #{@due.size} (Rs. #{money(@due.sum(:total))})",
      "Voided bills: #{@voided.size} (Rs. #{money(@voided.sum(:total))})",
      "Cancelled unpaid: #{@deleted.size}",
      "",
      "Channel",
      "- Dine-in: Rs. #{money(dine_in_sum)} (#{dine_in_count})",
      "- Take Away: Rs. #{money(takeaway_sum)} (#{takeaway_count})",
      "",
      "Payments collected",
      "- Cash: Rs. #{money(cash)}",
      "- UPI: Rs. #{money(upi)}",
      "- Card: Rs. #{money(card)}"
    ]

    if @bills.any?
      lines << ""
      lines << "Bills"
      @bills.each do |bill|
        place = bill.dining_table.takeaway? ? "Take Away" : bill.dining_table.display_name
        cashier = bill.cashier_label
        guest = bill.guest_name
        extra = [ cashier, guest ].compact.join(" / ")
        lines << "- #{bill.bill_number} | #{place} | #{bill.payment_method_label} | Rs. #{money(bill.total)}#{extra.present? ? " | #{extra}" : ""}"
      end
    else
      lines << ""
      lines << "No paid bills for this date."
    end

    if @voided.any?
      lines << ""
      lines << "Voided (not in collection)"
      @voided.each do |bill|
        lines << "- #{bill.bill_number} | Rs. #{money(bill.total)} | #{bill.void_reason}"
      end
    end

    lines << ""
    lines << "Sent from Hotel Sikkolu"
    lines.join("\n")
  end

  def html_body
    "<pre style=\"font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: 14px; line-height: 1.45; white-space: pre-wrap;\">#{ERB::Util.html_escape(body)}</pre>"
  end

  private

  def money(amount)
    format("%.2f", amount.to_f)
  end
end
