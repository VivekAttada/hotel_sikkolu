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
  end

  def render
    Prawn::Document.new(
      page_size: [ RECEIPT_WIDTH, estimated_page_height ],
      margin: MARGIN
    ) do |pdf|
      pdf.font "Helvetica"
      pdf.fill_color "000000"

      pdf.text "HOTEL SIKKOLU", size: 14, style: :bold, align: :center
      pdf.text "GSTIN: #{Bill::GSTIN}", size: 10, style: :bold, align: :center
      pdf.text "Bill Receipt", size: 11, style: :bold, align: :center
      pdf.move_down 6

      pdf.text "Bill No: #{@bill.bill_number}", size: 10, style: :bold
      if @bill.dining_table.takeaway?
        pdf.text "Type: Take Away", size: 10, style: :bold
      else
        pdf.text "Table: #{@bill.dining_table.name}", size: 10, style: :bold
      end
      pdf.text "Opened: #{@bill.opened_at.strftime('%d %b %Y, %I:%M %p')}", size: 10, style: :bold
      pdf.text "Paid: #{@bill.paid_at&.strftime('%d %b %Y, %I:%M %p') || '-'}", size: 10, style: :bold
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

      pdf.table(rows, width: pdf.bounds.width, header: true, cell_style: { size: 10, padding: [ 3, 2, 3, 2 ], font_style: :bold, text_color: "000000" }) do
        row(0).font_style = :bold
        cells.borders = [ :bottom ]
        cells.border_color = "000000"
        cells.border_width = 1.5
        columns(1..3).align = :right
      end

      pdf.move_down 8
      pdf.fill_color "000000"
      pdf.text "Thank you for dining at Hotel Sikkolu!", size: 9, align: :center, style: :bold
    end.render
  end

  private

  def estimated_page_height
    line_count = 9 # header/meta including GSTIN
    line_count += @line_items.size + 5
    line_count += @line_items.count { |line| line.note.present? }
    line_count += 2 # thanks

    height = (MARGIN * 2) + (line_count * 15) + 24
    [ height, 160 ].max
  end

  def truncate(text, max)
    text = text.to_s
    return text if text.length <= max

    "#{text[0, max - 1]}…"
  end
end
