class BillLineItem < ApplicationRecord
  belongs_to :bill
  belongs_to :menu_item, optional: true

  validates :item_name, :unit_price, :quantity, :line_total, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, :line_total, numericality: { greater_than_or_equal_to: 0 }
  validates :kot_sent_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :recalculate_total
  before_validation :clamp_kot_sent_quantity

  def recalculate_total!
    recalculate_total
  end

  def pending_kot_quantity
    [ quantity.to_i - kot_sent_quantity.to_i, 0 ].max
  end

  def kot_pending?
    pending_kot_quantity.positive?
  end

  private

  def recalculate_total
    self.line_total = unit_price.to_d * quantity.to_i
  end

  def clamp_kot_sent_quantity
    self.kot_sent_quantity = 0 if kot_sent_quantity.blank?
    self.kot_sent_quantity = [ kot_sent_quantity.to_i, quantity.to_i ].min
  end
end
