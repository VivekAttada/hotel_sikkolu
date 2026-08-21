class AddKotSentQuantityToBillLineItems < ActiveRecord::Migration[8.1]
  def change
    add_column :bill_line_items, :kot_sent_quantity, :integer, null: false, default: 0
  end
end
