class ChecklistEntry < ApplicationRecord
  belongs_to :daily_checklist
  belongs_to :checklist_task

  validates :checklist_task_id, uniqueness: { scope: :daily_checklist_id }

  def toggle!(checked_value)
    update!(
      checked: checked_value,
      checked_at: checked_value ? Time.current : nil
    )
  end
end
