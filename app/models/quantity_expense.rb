class QuantityExpense < ApplicationRecord
  belongs_to :inventory_item

  validates :quantity_used, presence: true, numericality: { greater_than: 0 }

  delegate :item_name, :daily_inventory, to: :inventory_item
end
