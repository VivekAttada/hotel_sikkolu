class DailyChecklist < ApplicationRecord
  has_many :checklist_entries, dependent: :destroy
  has_many :checklist_tasks, through: :checklist_entries

  validates :checklist_date, presence: true, uniqueness: true

  def self.for_date(date = Date.current)
    find_or_create_by!(checklist_date: date)
  end

  def self.ensure_entries_for(date = Date.current)
    daily = for_date(date)

    ChecklistTask.active_tasks.find_each do |task|
      daily.checklist_entries.find_or_create_by!(checklist_task: task)
    end

    daily
  end

  def completion_percentage
    entries = checklist_entries.joins(:checklist_task).merge(ChecklistTask.active_tasks)
    total = entries.count
    return 0 if total.zero?

    (entries.where(checked: true).count * 100.0 / total).round
  end
end
