class GroceryItem < ApplicationRecord
  validates :item_name, :imported_at, presence: true

  scope :recent_first, -> { order(Arel.sql("COALESCE(serial_no, 999999) ASC"), :item_name) }

  def self.import_from_spreadsheet(file)
    imported_at = Time.current
    items = ExcelImporter.parse_grocery(file)
    raise ArgumentError, "No valid grocery rows found in the uploaded sheet." if items.empty?

    transaction do
      delete_all
      items.each do |row|
        create!(
          serial_no: row[:serial_no],
          item_name: row[:item_name],
          old_stock: row[:old_stock] || 0,
          new_stock_added: row[:new_stock_added] || 0,
          unit: row[:unit],
          quantity: row[:quantity] || 0,
          imported_at: imported_at
        )
      end
    end

    count
  end

  def total_updated_stock
    quantity
  end

  def apply_total_stock!
    self.quantity = old_stock.to_d + new_stock_added.to_d
  end
end
