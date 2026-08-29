class AddPaymentMethodToBills < ActiveRecord::Migration[8.1]
  def change
    add_column :bills, :payment_method, :string
    add_index :bills, :payment_method
  end
end
