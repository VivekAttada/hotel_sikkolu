class InventoryItem < ApplicationRecord
  belongs_to :daily_inventory
  has_many :quantity_expenses, dependent: :destroy

  validates :item_name, presence: true
  validates :item_name, uniqueness: { scope: :daily_inventory_id }
  validates :opening_quantity, :current_quantity, numericality: { greater_than_or_equal_to: 0 }

  def record_expense!(quantity_used, notes: nil)
    quantity_used = quantity_used.to_d
    raise ArgumentError, "Quantity must be greater than zero" if quantity_used <= 0
    raise ArgumentError, "Not enough quantity available" if quantity_used > current_quantity

    transaction do
      quantity_expenses.create!(quantity_used: quantity_used, notes: notes)
      update!(current_quantity: current_quantity - quantity_used)
    end
  end

  def total_used
    opening_quantity - current_quantity
  end
end
