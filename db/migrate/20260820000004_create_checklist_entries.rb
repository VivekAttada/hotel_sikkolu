class CreateChecklistEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :checklist_entries do |t|
      t.references :daily_checklist, null: false, foreign_key: true
      t.references :checklist_task, null: false, foreign_key: true
      t.boolean :checked, default: false, null: false
      t.datetime :checked_at

      t.timestamps
    end

    add_index :checklist_entries, [ :daily_checklist_id, :checklist_task_id ], unique: true, name: "index_checklist_entries_on_daily_and_task"
  end
end
