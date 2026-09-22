require "test_helper"

class BillingSecurityTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email: "admin-int@sikkolu.test",
      username: "admin_int",
      password: "password123",
      role: "admin",
      name: "Admin Int"
    )
    @staff = User.create!(
      email: "staff-int@sikkolu.test",
      username: "staff_int",
      password: "password123",
      role: "staff",
      name: "Staff Int"
    )
    @other_staff = User.create!(
      email: "staff-two@sikkolu.test",
      username: "staff_two",
      password: "password123",
      role: "staff",
      name: "Other Staff"
    )
    @manager = User.create!(
      email: "manager-int@sikkolu.test",
      username: "manager_int",
      password: "password123",
      role: "manager",
      name: "Manager Int"
    )
    @table = DiningTable.create!(name: "T88", position: 88, active: true)
    @tea = MenuItem.create!(name: "Int Tea", category: "Beverages", price: 40, position: 1, active: true)
  end

  test "staff cannot open payments" do
    sign_in @staff
    get payments_path
    assert_redirected_to bills_path
  end

  test "staff cannot print another cashier paid bill" do
    Current.user = @staff
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)
    bill.mark_paid!(user: @staff, payment_method: "cash")

    sign_in @other_staff
    get bill_pdf_path(bill)
    assert_redirected_to bills_path
  end

  test "staff who settled can print the receipt" do
    Current.user = @staff
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)
    bill.mark_paid!(user: @staff, payment_method: "cash")

    sign_in @staff
    get bill_print_path(bill)
    assert_response :success
  end

  test "second KOT print sends only new items to kitchen" do
    Current.user = @staff
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)

    sign_in @staff
    post bill_kot_path(bill)
    assert_response :success
    assert_match @tea.name, response.body
    assert_no_match "ADDITIONAL KOT", response.body

    other = MenuItem.create!(name: "Int Coffee", category: "Beverages", price: 50, position: 2, active: true)
    bill.add_menu_item!(other, quantity: 1)

    post bill_kot_path(bill)
    assert_response :success
    assert_match "ADDITIONAL KOT", response.body
    assert_match other.name, response.body
    assert_no_match @tea.name, response.body
  end

  test "kot is not available over GET" do
    Current.user = @staff
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)
    sign_in @staff
    get "/bills/#{bill.id}/kot"
    assert_response :not_found
  end

  test "staff cannot void a paid bill" do
    Current.user = @staff
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)
    bill.mark_paid!(user: @staff, payment_method: "cash")

    sign_in @staff
    post void_bill_path(bill), params: { void_reason: "hide cash" }
    follow_redirect!
    assert_not bill.reload.voided?
  end

  test "admin void keeps the bill row" do
    Current.user = @staff
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)
    bill.mark_paid!(user: @staff, payment_method: "cash")

    sign_in @admin
    post void_bill_path(bill), params: { void_reason: "training" }
    assert bill.reload.voided?
    assert Bill.exists?(bill.id)
    assert_not_includes Bill.for_day(bill.service_date), bill
  end

  test "staff cannot open paid bills" do
    sign_in @staff
    get paid_bills_path
    assert_redirected_to bills_path
  end

  test "manager can see paid bills on the paid bills page" do
    Current.user = @staff
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)
    bill.mark_paid!(user: @staff, payment_method: "cash")

    sign_in @manager
    get paid_bills_path
    assert_response :success
    assert_match bill.bill_number, response.body
    assert_match "Paid Bills", response.body
    assert_no_match "Void reason", response.body
    assert_no_match "View payments", response.body
  end

  test "manager bill management links to paid bills and does not list them inline" do
    Current.user = @staff
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)
    bill.mark_paid!(user: @staff, payment_method: "cash")

    sign_in @manager
    get bills_path
    assert_response :success
    assert_match "Paid bills", response.body
    assert_select "#paid-bills-tab"
    assert_no_match "View payments", response.body
  end

  test "staff who opened an unpaid bill can print it before settle" do
    Current.user = @staff
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)

    sign_in @staff
    get bill_print_path(bill)
    assert_response :success
    assert_match "Unpaid", response.body
    assert_match "CGST", response.body
    assert_match "SGST", response.body
  end

  test "settle and save records sales without opening print" do
    Current.user = @staff
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)

    sign_in @staff
    post pay_bill_path(bill), params: { payment_method: "cash", discount_percent: 0 }
    assert_redirected_to bills_path
    follow_redirect!
    assert_match "Settled and saved", response.body
    assert bill.reload.paid?
  end

  test "staff cannot open bill edit history" do
    sign_in @staff
    get bill_edits_path
    assert_redirected_to bills_path
  end

  test "admin can open bill edit history" do
    Current.user = @staff
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)

    sign_in @admin
    get bill_edits_path
    assert_response :success
    assert_match "Bill Edit History", response.body
    assert_match "Added", response.body
  end

  test "staff cannot open cancelled kots" do
    sign_in @staff
    get cancelled_kots_path
    assert_redirected_to bills_path
  end

  test "admin cancelled kots lists post-KOT removals and bills omit them" do
    Current.user = @staff
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)
    coffee = MenuItem.create!(name: "Int Coffee Two", category: "Beverages", price: 50, position: 3, active: true)
    bill.add_menu_item!(coffee, quantity: 1)
    bill.issue_kot!
    bill.mark_kot_sent!
    tea_line = bill.bill_line_items.find_by(item_name: @tea.name)
    bill.remove_line_item!(tea_line)

    sign_in @staff
    get bill_print_path(bill)
    assert_response :success
    assert_match coffee.name, response.body
    assert_no_match "Removed during settlement", response.body
    assert_no_match "Removed after KOT", response.body

    sign_in @admin
    get cancelled_kots_path
    assert_response :success
    assert_match "Cancelled KOTs", response.body
    assert_match @tea.name, response.body
    assert_match bill.bill_number, response.body
  end

  test "manager can print any paid bill" do
    Current.user = @staff
    bill = Bill.open_for!(@table, user: @staff)
    bill.add_menu_item!(@tea, quantity: 1)
    bill.mark_paid!(user: @staff, payment_method: "cash")

    sign_in @manager
    get bill_print_path(bill)
    assert_response :success
  end
end
