class GroceryItem < ApplicationRecord
  validates :item_name, :imported_at, presence: true

  scope :recent_first, -> { order(imported_at: :desc, item_name: :asc) }

  def self.import_from_spreadsheet(file)
    imported_at = Time.current
    items = ExcelImporter.parse(file)

    transaction do
      delete_all
      items.each do |row|
        create!(
          item_name: row[:item_name],
          category: row[:category],
          quantity: row[:quantity] || 0,
          unit: row[:unit],
          price: row[:price] || 0,
          supplier: row[:supplier],
          notes: row[:notes],
          imported_at: imported_at
        )
      end
    end

    count
  end
end
