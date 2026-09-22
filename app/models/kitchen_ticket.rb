class KitchenTicket < ApplicationRecord
  belongs_to :bill

  validates :kot_number, :service_date, presence: true
  validates :kot_number, uniqueness: { scope: :service_date }
  validates :kot_number, numericality: { only_integer: true, greater_than: 0 }
end
