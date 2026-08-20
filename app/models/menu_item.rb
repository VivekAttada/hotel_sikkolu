class MenuItem < ApplicationRecord
  has_many :bill_line_items, dependent: :nullify

  CATEGORY_ORDER = [
    "Soups",
    "Veg Starters",
    "Non-Veg Starters",
    "Seafood Starters",
    "Tandoori",
    "Main Course Veg",
    "Main Course Egg",
    "Main Course Non-Veg",
    "Seafood Curries",
    "Main Course Mutton",
    "Biryani",
    "Rice",
    "Breads",
    "Extras",
    "Beverages"
  ].freeze

  validates :name, :price, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  scope :available, -> { where(active: true).order(:category, :position, :name) }

  def self.by_category
    available.group_by { |item| item.category.presence || "Other" }
      .sort_by { |category, _items| CATEGORY_ORDER.index(category) || CATEGORY_ORDER.size }
      .to_h
  end
end
