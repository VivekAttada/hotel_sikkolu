class XlsxExporter
  MIME_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

  class << self
    def grocery_items(items)
      yesterday = (Date.current - 1.day).strftime("%d/%m")
      build(filename: "hotel_sikkolu_grocery_#{date_stamp}.xlsx") do |workbook|
        add_sheet(workbook, "Grocery Inventory") do |sheet|
          sheet.add_row [ "HOTEL SIKKOLU - Chicken & Item Inventory Update (Date: #{Date.current.strftime('%d/%m/%Y')})" ]
          sheet.add_row []
          sheet.add_row [ "Sl No.", "Item Name", "Old Stock (#{yesterday})", "New Stock Added", "Qty", "Total Updated Stock", "Issued", "Total" ]
          items.each_with_index do |item, index|
            sheet.add_row [
              item.serial_no.presence || (index + 1),
              item.item_name,
              item.old_stock,
              item.new_stock_added,
              item.unit,
              "#{number_format(item.quantity)} #{item.unit}".strip,
              "#{number_format(item.issued)} #{item.unit}".strip,
              "#{number_format(item.available_total)} #{item.unit}".strip
            ]
          end
        end
      end
    end

    def grocery_sample_template
      yesterday = (Date.current - 1.day).strftime("%d/%m")

      build(filename: "hotel_sikkolu_grocery_sample.xlsx") do |workbook|
        add_sheet(workbook, "Inventory Update") do |sheet|
          sheet.add_row [ "HOTEL SIKKOLU - Chicken & Item Inventory Update (Date: #{Date.current.strftime('%d/%m/%Y')})" ]
          sheet.add_row []
          sheet.add_row [ "Sl No.", "Item Name", "Old Stock (#{yesterday})", "New Stock Added", "Qty", "Total Updated Stock", "Issued", "Total" ]
          sheet.add_row [ 1, "Tandoori", 12.5, 10, "Pcs", "22.5 Pcs", "2", "20.5 Pcs" ]
        end
      end
    end

    def quantity_sample_template
      build(filename: "hotel_sikkolu_quantities_sample.xlsx") do |workbook|
        add_sheet(workbook, "Daily Quantities") do |sheet|
          sheet.add_row [ "HOTEL SIKKOLU - Daily Opening Quantities (Date: #{Date.current.strftime('%d/%m/%Y')})" ]
          sheet.add_row []
          sheet.add_row [ "Item Name", "Quantity", "Unit" ]
          sheet.add_row [ "Rice", 50, "kg" ]
        end
      end
    end

    def checklist(daily_checklist, entries)
      date_label = daily_checklist.checklist_date.strftime("%Y-%m-%d")
      build(filename: "checklist_#{date_label}.xlsx") do |workbook|
        add_sheet(workbook, "Checklist") do |sheet|
          sheet.add_row [ "Date", daily_checklist.checklist_date.strftime("%A, %d %B %Y") ]
          sheet.add_row [ "Completion", "#{daily_checklist.completion_percentage}%" ]
          sheet.add_row []

          current_frequency = nil
          row_number = 0
          entries.each do |entry|
            if entry.checklist_task.frequency != current_frequency
              current_frequency = entry.checklist_task.frequency
              sheet.add_row []
              sheet.add_row [ current_frequency.titleize ]
              sheet.add_row [ "#", "Task", "Frequency", "Checked", "Checked At" ]
              row_number = 0
            end

            row_number += 1
            sheet.add_row [
              row_number,
              entry.checklist_task.title,
              entry.checklist_task.frequency.titleize,
              entry.checked ? "Yes" : "No",
              entry.checked_at&.strftime("%d %b %Y %I:%M %p")
            ]
          end
        end
      end
    end

    def quantities(daily_inventory, inventory_items, expenses)
      date_label = daily_inventory.inventory_date.strftime("%Y-%m-%d")
      build(filename: "quantities_#{date_label}.xlsx") do |workbook|
        add_sheet(workbook, "Inventory") do |sheet|
          sheet.add_row [ "Date", daily_inventory.inventory_date.strftime("%A, %d %B %Y") ]
          sheet.add_row []
          sheet.add_row [ "Item", "Opening", "Used", "Available", "Unit" ]
          inventory_items.each do |item|
            sheet.add_row [
              item.item_name,
              item.opening_quantity,
              item.total_used,
              item.current_quantity,
              item.unit
            ]
          end
        end

        add_sheet(workbook, "Expenses") do |sheet|
          sheet.add_row [ "Item", "Quantity Used", "Notes", "Recorded At" ]
          expenses.each do |expense|
            sheet.add_row [
              expense.item_name,
              expense.quantity_used,
              expense.notes,
              expense.created_at.strftime("%d %b %Y %I:%M %p")
            ]
          end
        end
      end
    end

    def team_members(members)
      build(filename: "hotel_sikkolu_team_#{date_stamp}.xlsx") do |workbook|
        add_sheet(workbook, "Team") do |sheet|
          sheet.add_row [ "#", "Name", "Description" ]
          members.each_with_index do |member, index|
            sheet.add_row [ index + 1, member.name, member.description ]
          end
        end
      end
    end

    private

    def build(filename:)
      package = Axlsx::Package.new
      yield package.workbook
      [ package.to_stream.read, filename ]
    end

    def add_sheet(workbook, name)
      workbook.add_worksheet(name: name) do |sheet|
        yield sheet
      end
    end

    def date_stamp
      Date.current.strftime("%Y-%m-%d")
    end

    def number_format(value)
      return "" if value.blank?

      format("%.3f", value).sub(/\.?0+\z/, "")
    end
  end
end
