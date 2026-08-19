class ChecklistTask < ApplicationRecord
  has_many :checklist_entries, dependent: :destroy

  FREQUENCIES = %w[daily weekly monthly].freeze

  enum :frequency, { daily: "daily", weekly: "weekly", monthly: "monthly" }, validate: true

  validates :title, presence: true

  scope :active_tasks, -> { where(active: true).order(Arel.sql("CASE frequency WHEN 'daily' THEN 1 WHEN 'weekly' THEN 2 WHEN 'monthly' THEN 3 END"), :position, :id) }
end
