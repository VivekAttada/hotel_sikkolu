class BillEdit < ApplicationRecord
  belongs_to :bill
  belongs_to :user, optional: true

  ACTIONS = %w[
    added_item
    updated_quantity
    updated_note
    removed_item
    applied_discount
    guest_updated
    settled
    cancelled
    voided
    restored
  ].freeze

  validates :action, :summary, :bill_number, :service_date, presence: true
  validates :action, inclusion: { in: ACTIONS }

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
  scope :for_day, ->(date) { where(service_date: date) }

  def action_label
    action.to_s.tr("_", " ").titleize
  end

  def actor_label
    user&.display_name || "System"
  end
end
