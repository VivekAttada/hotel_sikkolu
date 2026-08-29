class BillRemoval < ApplicationRecord
  belongs_to :bill
  belongs_to :menu_item, optional: true

  validates :item_name, :quantity, :unit_price, :line_total, :removed_at, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, :line_total, numericality: { greater_than_or_equal_to: 0 }

  scope :recent_first, -> { order(removed_at: :desc, id: :desc) }
end
