class CreateDailyChecklists < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_checklists do |t|
      t.date :checklist_date, null: false

      t.timestamps
    end

    add_index :daily_checklists, :checklist_date, unique: true
  end
end
