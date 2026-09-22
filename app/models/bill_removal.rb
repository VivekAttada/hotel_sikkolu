class BillRemoval < ApplicationRecord
  belongs_to :bill
  belongs_to :menu_item, optional: true
  belongs_to :removed_by, class_name: "User", optional: true

  validates :item_name, :quantity, :unit_price, :line_total, :removed_at, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, :line_total, numericality: { greater_than_or_equal_to: 0 }

  scope :recent_first, -> { order(removed_at: :desc, id: :desc) }
  scope :for_business_date, ->(date) {
    start_at = date.in_time_zone.change(hour: Bill::BUSINESS_DAY_CUTOFF_HOUR)
    where(removed_at: start_at...(start_at + 1.day))
  }

  def actor_label
    removed_by&.display_name || bill&.cashier_label || "—"
  end
end
