class DailyInventory < ApplicationRecord
  has_many :inventory_items, dependent: :destroy

  validates :inventory_date, presence: true, uniqueness: true

  def self.for_date(date = Date.current)
    find_by(inventory_date: date)
  end

  def self.import_from_spreadsheet(file, date: Date.current)
    rows = ExcelImporter.parse(file)

    transaction do
      inventory = find_or_initialize_by(inventory_date: date)
      inventory.notes = "Imported at #{Time.current.strftime('%I:%M %p')}"
      inventory.save!

      inventory.inventory_items.destroy_all

      rows.each do |row|
        quantity = row[:quantity] || row[:opening_quantity] || 0
        inventory.inventory_items.create!(
          item_name: row[:item_name],
          unit: row[:unit],
          opening_quantity: quantity,
          current_quantity: quantity
        )
      end

      inventory
    end
  end

  def total_items
    inventory_items.count
  end

  def total_remaining
    inventory_items.sum(:current_quantity)
  end
end
