class GroceryItem < ApplicationRecord
  validates :item_name, :imported_at, presence: true
  validates :issued, numericality: { greater_than_or_equal_to: 0 }
  validate :issued_not_greater_than_stock

  scope :recent_first, -> { order(Arel.sql("COALESCE(serial_no, 999999) ASC"), :item_name) }

  def self.import_from_spreadsheet(file)
    imported_at = Time.current
    items = ExcelImporter.parse_grocery(file)
    raise ArgumentError, "No valid grocery rows found in the uploaded sheet." if items.empty?

    transaction do
      delete_all
      items.each do |row|
        item = new(
          serial_no: row[:serial_no],
          item_name: row[:item_name],
          old_stock: row[:old_stock] || 0,
          new_stock_added: row[:new_stock_added] || 0,
          unit: row[:unit],
          issued: row[:issued] || 0,
          imported_at: imported_at
        )
        item.apply_total_stock!
        item.save!
      end
    end

    count
  end

  def total_updated_stock
    quantity
  end

  def available_total
    quantity.to_d - issued.to_d
  end

  def apply_total_stock!
    self.quantity = old_stock.to_d + new_stock_added.to_d
    self.issued = 0 if issued.blank?
  end

  private

  def issued_not_greater_than_stock
    return if issued.blank? || quantity.blank?
    return if issued.to_d <= quantity.to_d

    errors.add(:issued, "cannot be more than total updated stock (#{quantity})")
  end
end
