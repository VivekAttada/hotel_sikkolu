class DiningTable < ApplicationRecord
  has_many :bills, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  scope :ordered, -> { where(active: true).order(:position, :id) }

  def active_bill
    bills.active.order(opened_at: :desc).first
  end

  def occupied?
    active_bill.present?
  end
end
