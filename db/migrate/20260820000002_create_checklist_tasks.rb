class CreateChecklistTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :checklist_tasks do |t|
      t.string :title, null: false
      t.integer :position, default: 0, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :checklist_tasks, :position
  end
end
