class AddDiscountPercentAndBillEdits < ActiveRecord::Migration[8.1]
  def change
    add_column :bills, :discount_percent, :decimal, precision: 5, scale: 2, default: "0.0", null: false

    create_table :bill_edits do |t|
      t.integer :bill_id, null: false
      t.integer :user_id
      t.string :action, null: false
      t.string :summary, null: false
      t.json :details
      t.string :bill_number, null: false
      t.date :service_date, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.index :bill_id
      t.index :user_id
      t.index :service_date
      t.index :created_at
      t.index :action
    end

    add_foreign_key :bill_edits, :bills
    add_foreign_key :bill_edits, :users
  end
end
