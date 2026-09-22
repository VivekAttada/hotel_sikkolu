class BillPdf
  # ~80mm thermal receipt width in PDF points
  RECEIPT_WIDTH = 226
  MARGIN = 10

  def self.generate(bill)
    new(bill).render
  end

  def initialize(bill)
    @bill = bill
    @line_items = bill.bill_line_items.order(:id).to_a
    @removals = bill.bill_removals.order(:removed_at, :id).to_a
  end

  def render
    Prawn::Document.new(
      page_size: [ RECEIPT_WIDTH, estimated_page_height ],
      margin: MARGIN
    ) do |pdf|
      pdf.font "Courier"

      pdf.text "HOTEL SIKKOLU", size: 11, style: :bold, align: :center
      pdf.text "GSTIN: #{Bill::GSTIN}", size: 8, align: :center
      pdf.text "Bill Receipt", size: 9, align: :center
      pdf.move_down 6

      pdf.text "Bill No: #{@bill.bill_number}", size: 8
      if @bill.dining_table.takeaway?
        pdf.text "Type: Take Away", size: 8
      else
        pdf.text "Table: #{@bill.dining_table.name}", size: 8
      end
      pdf.text "Opened: #{@bill.opened_at.strftime('%d %b %Y, %I:%M %p')}", size: 8
      pdf.text "Paid: #{@bill.paid_at&.strftime('%d %b %Y, %I:%M %p') || '-'}", size: 8
      pdf.move_down 6

      rows = [ [ "Item", "Qty", "Rate", "Amt" ] ]
      @line_items.each do |line|
        item_label = truncate(line.item_name, 18)
        item_label = "#{item_label}\n#{truncate(line.note, 18)}" if line.note.present?
        rows << [
          item_label,
          line.quantity.to_s,
          format("%.2f", line.unit_price),
          format("%.2f", line.line_total)
        ]
      end
      rows << [
        { content: "Total", colspan: 3, align: :right },
        format("%.2f", @bill.subtotal)
      ]
      if @bill.discount_amount.to_d.positive? || @bill.complementary?
        discount_label = @bill.complementary? ? "Discount (NC)" : "Discount"
        if @bill.discount_percent.to_d.positive? && !@bill.complementary?
          discount_label = "Discount #{format('%g', @bill.discount_percent)}%"
        end
        rows << [
          { content: discount_label, colspan: 3, align: :right },
          format("- %.2f", @bill.discount_amount)
        ]
      end
      rows << [
        { content: "CGST #{Bill::CGST_PERCENT}%", colspan: 3, align: :right },
        format("%.2f", @bill.cgst_amount)
      ]
      rows << [
        { content: "SGST #{Bill::SGST_PERCENT}%", colspan: 3, align: :right },
        format("%.2f", @bill.sgst_amount)
      ]
      rows << [
        { content: "GRAND TOTAL", colspan: 3, align: :right, font_style: :bold },
        { content: "Rs. #{format('%.2f', @bill.total)}", font_style: :bold }
      ]

      pdf.table(rows, width: pdf.bounds.width, header: true, cell_style: { size: 8, padding: [ 2, 2, 2, 2 ] }) do
        row(0).font_style = :bold
        row(0).background_color = "3D4B35"
        row(0).text_color = "FFFFFF"
        cells.borders = [ :bottom ]
        columns(1..3).align = :right
      end

      if @removals.any?
        pdf.move_down 8
        pdf.fill_color "B00020"
        pdf.text "Removed during settlement", size: 8, style: :bold
        pdf.move_down 3

        removal_rows = [ [ "Item", "Qty", "Rate", "Amt" ] ]
        @removals.each do |removal|
          removal_rows << [
            truncate(removal.item_name, 18),
            removal.quantity.to_s,
            format("%.2f", removal.unit_price),
            format("%.2f", removal.line_total)
          ]
        end

        pdf.table(removal_rows, width: pdf.bounds.width, header: true, cell_style: { size: 8, padding: [ 2, 2, 2, 2 ] }) do
          row(0).font_style = :bold
          cells.text_color = "B00020"
          cells.borders = [ :bottom ]
          cells.border_color = "E0A0A8"
          columns(1..3).align = :right
        end

        reason = @removals.map(&:reason).compact_blank.uniq.join(" / ")
        if reason.present?
          pdf.move_down 4
          pdf.text "Reason: #{reason}", size: 7, style: :italic
        end
        pdf.fill_color "000000"
      end

      pdf.move_down 8
      pdf.text "Thank you for dining at Hotel Sikkolu!", size: 7, align: :center, style: :italic
    end.render
  end

  private

  def estimated_page_height
    line_count = 9 # header/meta including GSTIN
    line_count += @line_items.size + 5
    line_count += @line_items.count { |line| line.note.present? }
    if @removals.any?
      line_count += @removals.size + 4
      line_count += 2 if @removals.any? { |r| r.reason.present? }
    end
    line_count += 2 # thanks

    height = (MARGIN * 2) + (line_count * 12) + 20
    [ height, 160 ].max
  end

  def truncate(text, max)
    text = text.to_s
    return text if text.length <= max

    "#{text[0, max - 1]}…"
  end
end
