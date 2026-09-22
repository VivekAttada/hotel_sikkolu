class AddNoteToBillLineItems < ActiveRecord::Migration[8.1]
  def change
    add_column :bill_line_items, :note, :string
  end
end
