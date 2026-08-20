class AddDeletedAtToBills < ActiveRecord::Migration[8.1]
  def change
    add_column :bills, :deleted_at, :datetime
    add_index :bills, :deleted_at
  end
end
