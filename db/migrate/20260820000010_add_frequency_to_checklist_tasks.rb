class AddFrequencyToChecklistTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :checklist_tasks, :frequency, :string, default: "daily", null: false
    add_index :checklist_tasks, :frequency
  end
end
