class BillLineItem < ApplicationRecord
  belongs_to :bill
  belongs_to :menu_item, optional: true

  validates :item_name, :unit_price, :quantity, :line_total, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, :line_total, numericality: { greater_than_or_equal_to: 0 }

  before_validation :recalculate_total

  def recalculate_total!
    recalculate_total
  end

  private

  def recalculate_total
    self.line_total = unit_price.to_d * quantity.to_i
  end
end
