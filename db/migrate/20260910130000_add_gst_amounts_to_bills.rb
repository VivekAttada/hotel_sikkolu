class AddGstAmountsToBills < ActiveRecord::Migration[8.1]
  def up
    add_column :bills, :cgst_amount, :decimal, precision: 10, scale: 2, null: false, default: 0
    add_column :bills, :sgst_amount, :decimal, precision: 10, scale: 2, null: false, default: 0
    add_column :bills, :total, :decimal, precision: 10, scale: 2, null: false, default: 0

    say_with_time "Backfill CGST 2.5% and SGST 2.5% on existing bills" do
      cgst_rate = BigDecimal("0.025")
      sgst_rate = BigDecimal("0.025")

      connection.select_all("SELECT id, subtotal FROM bills").each do |row|
        items = BigDecimal(row["subtotal"].to_s)
        cgst = (items * cgst_rate).round(2)
        sgst = (items * sgst_rate).round(2)
        execute(ActiveRecord::Base.sanitize_sql_array([
          "UPDATE bills SET cgst_amount = ?, sgst_amount = ?, total = ? WHERE id = ?",
          cgst,
          sgst,
          items + cgst + sgst,
          row["id"]
        ]))
      end
    end
  end

  def down
    remove_column :bills, :total
    remove_column :bills, :sgst_amount
    remove_column :bills, :cgst_amount
  end
end
