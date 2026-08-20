class BillPdf
  def self.generate(bill)
    new(bill).render
  end

  def initialize(bill)
    @bill = bill
  end

  def render
    Prawn::Document.new(page_size: "A4", margin: 40) do |pdf|
      pdf.text "HOTEL SIKKOLU", size: 22, style: :bold, align: :center
      pdf.text "Bill Receipt", size: 14, align: :center
      pdf.move_down 16

      pdf.text "Bill No: #{@bill.bill_number}"
      pdf.text "Table: #{@bill.dining_table.name}"
      pdf.text "Opened: #{@bill.opened_at.strftime('%d %b %Y, %I:%M %p')}"
      pdf.text "Paid: #{@bill.paid_at&.strftime('%d %b %Y, %I:%M %p') || '-'}"
      pdf.text "Status: #{@bill.status.titleize}"
      pdf.move_down 16

      rows = [ [ "Item", "Qty", "Rate (Rs.)", "Amount (Rs.)" ] ]
      @bill.bill_line_items.order(:id).each do |line|
        rows << [
          line.item_name,
          line.quantity.to_s,
          format("%.2f", line.unit_price),
          format("%.2f", line.line_total)
        ]
      end
      rows << [
        { content: "TOTAL", colspan: 3, align: :right, font_style: :bold },
        { content: "Rs. #{format('%.2f', @bill.subtotal)}", font_style: :bold }
      ]

      pdf.table(rows, width: pdf.bounds.width, header: true) do
        row(0).font_style = :bold
        row(0).background_color = "3D4B35"
        row(0).text_color = "FFFFFF"
        cells.padding = 8
        cells.borders = [ :bottom ]
        columns(1..3).align = :right
      end

      pdf.move_down 24
      pdf.text "Thank you for dining at Hotel Sikkolu!", align: :center, style: :italic
    end.render
  end
end
