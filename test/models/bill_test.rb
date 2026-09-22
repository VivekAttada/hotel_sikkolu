require "test_helper"

class BillTest < ActiveSupport::TestCase
  setup do
    @admin = User.create!(
      email: "admin-test@sikkolu.test",
      username: "admin_test",
      password: "password123",
      role: "admin",
      name: "Admin Test"
    )
    @staff = User.create!(
      email: "staff-test@sikkolu.test",
      username: "staff_test",
      password: "password123",
      role: "staff",
      name: "Staff Test"
    )
    Current.user = @staff
    @table = DiningTable.create!(name: "T99", position: 99, active: true)
    @tea = MenuItem.create!(name: "Test Tea", category: "Beverages", price: 100, position: 1, active: true)
    @coffee = MenuItem.create!(name: "Test Coffee", category: "Beverages", price: 80, position: 2, active: true)
  end

  teardown { Current.user = nil }

  test "opening a table twice returns the same bill" do
    first = Bill.open_for!(@table, user: @staff)
    second = Bill.open_for!(@table, user: @staff)
    assert_equal first.id, second.id
  end

  test "same item with different notes stays on two lines" do
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1, note: "less sugar")
    bill.add_menu_item!(@tea, quantity: 1, note: "no sugar")
    assert_equal 2, bill.bill_line_items.count
  end

  test "same item with the same note merges quantity" do
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)
    bill.add_menu_item!(@tea, quantity: 2)
    assert_equal 1, bill.bill_line_items.count
    assert_equal 3, bill.bill_line_items.first.quantity
  end

  test "paying twice raises after lock" do
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)
    bill.mark_paid!(user: @staff, payment_method: "cash")
    assert_raises(ArgumentError) { bill.mark_paid!(user: @staff, payment_method: "upi") }
  end

  test "voided paid bill leaves collection but stays visible" do
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)
    bill.mark_paid!(user: @staff, payment_method: "cash")
    bill.void!(user: @admin, reason: "Wrong tender")
    assert bill.reload.voided?
    assert_not_includes Bill.for_day(bill.service_date), bill
    assert_includes Bill.voided_on(Time.zone.today), bill
  end

  test "staff cannot cancel after KOT" do
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)
    bill.issue_kot!
    bill.mark_kot_sent!
    assert_raises(ArgumentError) { bill.cancel!(user: @staff, reason: "guest left") }
  end

  test "admin can restore a void" do
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)
    bill.mark_paid!(user: @staff, payment_method: "cash")
    bill.void!(user: @admin, reason: "mistake")
    bill.restore_void!(user: @admin)
    assert_includes Bill.for_day(bill.service_date), bill.reload
  end

  test "split tender and due balance" do
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)
    total = bill.reload.total
    bill.mark_paid!(user: @staff, cash_amount: 50, upi_amount: 0, card_amount: 0, mark_due: true)
    assert bill.reload.due?
    assert_equal "cash", bill.payment_method
    assert bill.balance_due.positive?
    assert_equal 50, bill.cash_amount
    assert total > 50
  end

  test "second KOT only includes items added after the first KOT" do
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)
    bill.issue_kot!
    bill.mark_kot_sent!

    bill.add_menu_item!(@coffee, quantity: 2)
    pending = bill.bill_line_items.reload.select(&:kot_pending?)

    assert_equal 1, pending.size
    assert_equal @coffee.name, pending.first.item_name
    assert_equal 2, pending.first.pending_kot_quantity
    assert_equal 0, bill.bill_line_items.find_by(item_name: @tea.name).pending_kot_quantity
  end

  test "extra quantity of the same item is pending for the next KOT" do
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)
    bill.issue_kot!
    bill.mark_kot_sent!
    bill.add_menu_item!(@tea, quantity: 2)

    line = bill.bill_line_items.reload.first
    assert_equal 3, line.quantity
    assert_equal 1, line.kot_sent_quantity
    assert_equal 2, line.pending_kot_quantity
  end

  test "business date before 6am belongs to yesterday" do
    time = Time.zone.parse("#{Date.current} 05:00")
    assert_equal Date.current - 1, Bill.business_date_for(time)
  end

  test "discount percent recalculates GST on the taxable amount" do
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)
    bill.mark_paid!(user: @staff, payment_method: "cash", discount_percent: 10)

    bill.reload
    assert_equal 10, bill.discount_percent
    assert_equal 10, bill.discount_amount
    assert_equal 2.25, bill.cgst_amount
    assert_equal 2.25, bill.sgst_amount
    assert_equal 94.50, bill.total
    assert_equal 94.50, bill.cash_amount
    assert_includes bill.bill_edits.pluck(:action), "settled"
    assert_includes bill.bill_edits.pluck(:action), "added_item"
  end
end
