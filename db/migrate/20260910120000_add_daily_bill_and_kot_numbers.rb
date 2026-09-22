class AddDailyBillAndKotNumbers < ActiveRecord::Migration[8.1]
  def up
    add_column :bills, :service_date, :date
    remove_index :bills, :bill_number

    create_table :daily_sequences do |t|
      t.date :service_date, null: false
      t.string :kind, null: false
      t.integer :last_number, null: false, default: 0

      t.timestamps
    end
    add_index :daily_sequences, [ :service_date, :kind ], unique: true

    create_table :kitchen_tickets do |t|
      t.references :bill, null: false, foreign_key: true
      t.integer :kot_number, null: false
      t.date :service_date, null: false

      t.timestamps
    end
    add_index :kitchen_tickets, [ :service_date, :kot_number ], unique: true

    say_with_time "Renumber existing bills per day" do
      bills = connection.select_all("SELECT id, opened_at FROM bills ORDER BY opened_at ASC, id ASC")
      bills.group_by { |row| Time.zone.parse(row["opened_at"].to_s).to_date }.each do |date, rows|
        rows.each_with_index do |row, index|
          execute(sanitize_sql_array([
            "UPDATE bills SET service_date = ?, bill_number = ? WHERE id = ?",
            date.to_s,
            (index + 1).to_s,
            row["id"]
          ]))
        end

        now = Time.current
        execute(sanitize_sql_array([
          "INSERT INTO daily_sequences (service_date, kind, last_number, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
          date.to_s,
          "bill",
          rows.size,
          now,
          now
        ]))
      end
    end

    change_column_null :bills, :service_date, false
    add_index :bills, [ :service_date, :bill_number ], unique: true
  end

  def down
    remove_index :bills, column: [ :service_date, :bill_number ]
    drop_table :kitchen_tickets
    drop_table :daily_sequences
    remove_column :bills, :service_date
    add_index :bills, :bill_number, unique: true
  end

  private

  def sanitize_sql_array(array)
    ActiveRecord::Base.sanitize_sql_array(array)
  end
end
