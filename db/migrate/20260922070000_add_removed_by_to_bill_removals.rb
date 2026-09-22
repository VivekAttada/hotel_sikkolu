class AddRemovedByToBillRemovals < ActiveRecord::Migration[8.1]
  def change
    add_column :bill_removals, :removed_by_id, :integer
    add_index :bill_removals, :removed_by_id
    add_foreign_key :bill_removals, :users, column: :removed_by_id
  end
end
