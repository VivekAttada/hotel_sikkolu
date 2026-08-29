class DailyReport
  def self.body(date = Date.current)
    new(date).body
  end

  def self.whatsapp_url(date: Date.current, phone: nil)
    phone = AppSetting.normalized_whatsapp_number(phone.presence || AppSetting.whatsapp_number)
    return nil if phone.blank?

    "https://wa.me/#{phone}?text=#{ERB::Util.url_encode(body(date))}"
  end

  def initialize(date = Date.current)
    @date = date
    @bills = Bill.for_day(@date).includes(:dining_table, :bill_line_items).recent_first
    @deleted = Bill.deleted_on(@date)
  end

  def body
    total = @bills.sum(:subtotal)
    cash = @bills.where(payment_method: "cash").sum(:subtotal)
    upi = @bills.where(payment_method: "upi").sum(:subtotal)
    card = @bills.where(payment_method: "card").sum(:subtotal)

    takeaway_id = DiningTable.find_by(name: DiningTable::TAKEAWAY_NAME)&.id
    takeaway_sum = takeaway_id ? @bills.where(dining_table_id: takeaway_id).sum(:subtotal) : 0
    dine_in_sum = total - takeaway_sum
    takeaway_count = takeaway_id ? @bills.where(dining_table_id: takeaway_id).count : 0
    dine_in_count = @bills.size - takeaway_count

    lines = [
      "Hotel Sikkolu — Daily Report",
      "Date: #{@date.strftime('%d %b %Y')}",
      "",
      "TOTAL COLLECTION: Rs. #{money(total)}",
      "Paid bills: #{@bills.size}",
      "Deleted bills: #{@deleted.size}",
      "",
      "Channel",
      "- Dine-in: Rs. #{money(dine_in_sum)} (#{dine_in_count})",
      "- Take Away: Rs. #{money(takeaway_sum)} (#{takeaway_count})",
      "",
      "Payments",
      "- Cash: Rs. #{money(cash)}",
      "- UPI: Rs. #{money(upi)}",
      "- Card: Rs. #{money(card)}"
    ]

    if @bills.any?
      lines << ""
      lines << "Bills"
      @bills.each do |bill|
        place = bill.dining_table.takeaway? ? "Take Away" : bill.dining_table.display_name
        lines << "- #{bill.bill_number} | #{place} | #{bill.payment_method_label} | Rs. #{money(bill.subtotal)}"
      end
    else
      lines << ""
      lines << "No paid bills for this date."
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
