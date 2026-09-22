class GroceryImport < ApplicationRecord
  belongs_to :imported_by, class_name: "User", optional: true
  has_many :grocery_items, dependent: :nullify

  scope :recent_first, -> { order(imported_at: :desc, id: :desc) }
end
