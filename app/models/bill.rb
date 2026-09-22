class Bill < ApplicationRecord
  BUSINESS_DAY_CUTOFF_HOUR = 6

  belongs_to :dining_table
  belongs_to :opened_by, class_name: "User", optional: true
  belongs_to :paid_by, class_name: "User", optional: true
  belongs_to :voided_by, class_name: "User", optional: true
  belongs_to :cancelled_by, class_name: "User", optional: true
  has_many :bill_line_items, dependent: :destroy
  has_many :bill_removals, dependent: :destroy
  has_many :kitchen_tickets, dependent: :destroy
  has_many :bill_edits, dependent: :destroy

  STATUSES = %w[active due paid].freeze
  PAYMENT_METHODS = %w[cash upi card split nc due].freeze
  GSTIN = "37AATFH0073K1ZZ"
  CGST_PERCENT = 2.5
  SGST_PERCENT = 2.5
  CGST_RATE = BigDecimal("0.025")
  SGST_RATE = BigDecimal("0.025")

  validates :bill_number, :status, :opened_at, :service_date, presence: true
  validates :bill_number, uniqueness: { scope: :service_date }
  validates :status, inclusion: { in: STATUSES }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }, allow_nil: true
  validates :guest_phone, format: { with: /\A\+?\d{10,15}\z/, allow_blank: true, message: "must be 10–15 digits" }
  validate :only_one_active_bill_per_table, if: -> { open_on_table? && dining_table_id.present? && !takeaway_order? }

  before_validation :assign_defaults, on: :create
  before_validation :assign_dine_in_lock_key

  scope :kept, -> { where(deleted_at: nil) }
  scope :trashed, -> { where.not(deleted_at: nil) }
  scope :not_voided, -> { where(voided_at: nil) }
  scope :voided, -> { where.not(voided_at: nil) }
  scope :active, -> { kept.not_voided.where(status: "active") }
  scope :due, -> { kept.not_voided.where(status: "due") }
  scope :open_on_table, -> { kept.not_voided.where(status: %w[active due]) }
  scope :paid, -> { kept.not_voided.where(status: "paid") }
  scope :collected, -> { paid }
  scope :takeaway_orders, -> {
    joins(:dining_table).where(dining_tables: { name: DiningTable::TAKEAWAY_NAME })
  }
  scope :active_takeaways, -> { open_on_table.takeaway_orders.order(opened_at: :desc) }
  scope :for_day, ->(date) {
    collected.where(service_date: date)
  }
  scope :due_on, ->(date) {
    due.where(service_date: date)
  }
  scope :voided_on, ->(date) {
    zone_day = date.in_time_zone
    voided.where(voided_at: zone_day.beginning_of_day..zone_day.end_of_day)
  }
  scope :deleted_on, ->(date) {
    trashed.where(deleted_at: date.beginning_of_day..date.end_of_day)
  }
  scope :recent_first, -> { order(Arel.sql("COALESCE(paid_at, opened_at) DESC")) }
  scope :recently_deleted, -> { order(deleted_at: :desc) }

  def self.business_date_for(time = Time.current)
    local = time.in_time_zone
    local.hour < BUSINESS_DAY_CUTOFF_HOUR ? local.to_date - 1 : local.to_date
  end

  def active?
    status == "active" && !deleted? && !voided?
  end

  def due?
    status == "due" && !deleted? && !voided?
  end

  def paid?
    status == "paid" && !deleted? && !voided?
  end

  def open_on_table?
    (active? || due?) && !deleted? && !voided?
  end

  def deleted?
    deleted_at.present?
  end

  def voided?
    voided_at.present?
  end

  def collected?
    paid?
  end

  def self.open_for!(dining_table, user: Current.user)
    dining_table.with_lock do
      existing = dining_table.active_bill
      return existing if existing

      create!(dining_table: dining_table, opened_by: user)
    end
  rescue ActiveRecord::RecordNotUnique
    dining_table.reload.active_bill || raise
  end

  def self.create_takeaway!(user: Current.user, guest_name: nil, guest_phone: nil)
    create!(
      dining_table: DiningTable.takeaway!,
      opened_by: user,
      guest_name: guest_name,
      guest_phone: guest_phone
    )
  end

  def takeaway_order?
    dining_table&.takeaway?
  end

  def add_menu_item!(menu_item, quantity: 1, note: nil)
    raise ArgumentError, "Bill is cancelled" if deleted?
    raise ArgumentError, "Bill is voided" if voided?
    raise ArgumentError, "Bill is already paid" if status == "paid"

    quantity = quantity.to_i
    raise ArgumentError, "Quantity must be at least 1" if quantity < 1
    note_value = note.to_s.strip.presence

    transaction do
      line = bill_line_items.find_or_initialize_by(menu_item_id: menu_item.id, note: note_value)
      line.item_name = menu_item.name
      line.unit_price = menu_item.price if line.new_record?
      line.quantity = line.new_record? ? quantity : line.quantity + quantity
      line.recalculate_total!
      line.save!
      recalculate_subtotal!
      record_edit!(
        action: "added_item",
        summary: "Added #{quantity} × #{menu_item.name}",
        details: { item: menu_item.name, quantity: quantity, note: note_value }
      )
    end
  end

  def update_line_note!(line_item, note)
    assert_open_for_edit!
    previous = line_item.note
    line_item.update!(note: note.to_s.strip.presence)
    record_edit!(
      action: "updated_note",
      summary: "Updated note on #{line_item.item_name}",
      details: { item: line_item.item_name, from: previous, to: line_item.note }
    )
  end

  def update_line_quantity!(line_item, quantity)
    assert_open_for_edit!

    quantity = quantity.to_i
    previous = line_item.quantity
    name = line_item.item_name
    transaction do
      if quantity <= 0
        record_post_kot_removal!(line_item, line_item.kot_sent_quantity.to_i)
        line_item.destroy!
        record_edit!(
          action: "removed_item",
          summary: "Removed #{name} (qty #{previous})",
          details: { item: name, from: previous, to: 0 }
        )
      else
        removed_from_kot = [ line_item.kot_sent_quantity.to_i - quantity, 0 ].max
        record_post_kot_removal!(line_item, removed_from_kot)
        line_item.update!(quantity: quantity)
        line_item.recalculate_total!
        line_item.save!
        record_edit!(
          action: "updated_quantity",
          summary: "Changed #{name} from #{previous} to #{quantity}",
          details: { item: name, from: previous, to: quantity }
        )
      end
      recalculate_subtotal!
    end
  end

  def remove_line_item!(line_item)
    assert_open_for_edit!

    name = line_item.item_name
    qty = line_item.quantity
    transaction do
      record_post_kot_removal!(line_item, line_item.kot_sent_quantity.to_i)
      line_item.destroy!
      recalculate_subtotal!
      record_edit!(
        action: "removed_item",
        summary: "Removed #{name} × #{qty}",
        details: { item: name, quantity: qty }
      )
    end
  end

  def post_kot_removals?
    bill_removals.exists?
  end

  def kot_sent?
    bill_line_items.any? { |line| line.kot_sent_quantity.to_i.positive? } || kitchen_tickets.exists?
  end

  def amount_tendered
    cash_amount.to_d + upi_amount.to_d + card_amount.to_d
  end

  def balance_due
    [ total.to_d - amount_tendered, 0 ].max
  end

  def mark_paid!(user:, cash_amount: 0, upi_amount: 0, card_amount: 0, discount_amount: 0,
                 discount_percent: nil, discount_reason: nil, complementary: false, guest_name: nil, guest_phone: nil,
                 removal_reason: nil, mark_due: false, payment_method: nil)
    transaction do
      lock!
      reload
      raise ArgumentError, "Bill is cancelled" if deleted?
      raise ArgumentError, "Bill is voided" if voided?
      raise ArgumentError, "Bill is already paid" if status == "paid"
      raise ArgumentError, "Add at least one item before payment" if bill_line_items.empty?

      reason = removal_reason.to_s.strip
      if post_kot_removals? && reason.blank?
        raise ArgumentError, "Enter a reason for items removed after KOT"
      end

      self.guest_name = guest_name.to_s.strip.presence if guest_name
      self.guest_phone = guest_phone.to_s.gsub(/\s+/, "") if guest_phone
      apply_discount!(discount_amount, discount_reason, complementary, discount_percent: discount_percent)
      apply_tax_amounts

      cash = money(cash_amount)
      upi = money(upi_amount)
      card = money(card_amount)

      if complementary
        cash = upi = card = 0
        method = "nc"
        new_status = "paid"
      elsif payment_method.present? && cash.zero? && upi.zero? && card.zero?
        method = payment_method.to_s.strip.downcase
        raise ArgumentError, "Select payment method: Cash, UPI, or Card" unless %w[cash upi card].include?(method)
        case method
        when "cash" then cash = total.to_d
        when "upi" then upi = total.to_d
        when "card" then card = total.to_d
        end
        new_status = "paid"
      else
        tendered = cash + upi + card
        raise ArgumentError, "Enter cash, UPI, and/or card amounts" if tendered.zero? && !mark_due
        raise ArgumentError, "Collected amount cannot be more than the bill total" if tendered > total.to_d + BigDecimal("0.009")

        method = tender_method(cash, upi, card)
        new_status = if mark_due || tendered < total.to_d
          "due"
        else
          "paid"
        end
        method = "due" if new_status == "due" && tendered.zero?
      end

      if post_kot_removals?
        bill_removals.where(reason: [ nil, "" ]).update_all(reason: reason, updated_at: Time.current)
      end

      paid_time = Time.current
      update!(
        tax_attributes.merge(
          status: new_status,
          paid_at: new_status == "paid" ? paid_time : paid_at,
          payment_method: method,
          cash_amount: cash,
          upi_amount: upi,
          card_amount: card,
          paid_by: user,
          dine_in_lock_key: new_status == "due" ? dine_in_lock_key_value : nil
        )
      )
      record_edit!(
        user: user,
        action: "settled",
        summary: "Settled #{bill_number} as #{payment_method_label} — ₹ #{format('%.2f', total)}",
        details: {
          payment_method: method,
          total: total.to_s,
          discount_percent: discount_percent.to_s,
          cgst: cgst_amount.to_s,
          sgst: sgst_amount.to_s
        }
      )
    end
  end

  def void!(user:, reason:)
    raise ArgumentError, "Only admin can void a bill" unless user&.admin?
    raise ArgumentError, "Enter a void reason" if reason.to_s.strip.blank?

    transaction do
      lock!
      reload
      raise ArgumentError, "Bill is already cancelled" if deleted?
      raise ArgumentError, "Bill is already voided" if voided?
      raise ArgumentError, "Void is for paid or due bills" unless status.in?(%w[paid due])

      update!(
        voided_at: Time.current,
        void_reason: reason.to_s.strip,
        voided_by: user,
        dine_in_lock_key: nil
      )
      record_edit!(user: user, action: "voided", summary: "Voided #{bill_number}", details: { reason: reason.to_s.strip })
    end
  end

  def restore_void!(user:)
    raise ArgumentError, "Only admin can restore a voided bill" unless user&.admin?

    transaction do
      lock!
      reload
      raise ArgumentError, "Bill is not voided" unless voided?

      update!(voided_at: nil, void_reason: nil, voided_by: nil)
      record_edit!(user: user, action: "restored", summary: "Restored #{bill_number} to collection")
    end
  end

  def payment_method_label
    return "Voided" if voided?
    return "Due" if due?
    return "NC" if complementary? || payment_method == "nc"
    return "Split" if payment_method == "split"
    return "—" if payment_method.blank?

    payment_method.upcase == "UPI" ? "UPI" : payment_method.titleize
  end

  def save_guest!(name:, phone:, user: Current.user)
    update!(
      guest_name: name.to_s.strip.presence,
      guest_phone: phone.to_s.gsub(/\s+/, "").presence
    )
    record_edit!(
      user: user,
      action: "guest_updated",
      summary: "Updated guest details",
      details: { guest_name: guest_name, guest_phone: guest_phone }
    )
  end

  def cancel!(user:, reason: nil)
    raise ArgumentError, "Bill is already cancelled" if deleted?
    raise ArgumentError, "Paid bills must be voided, not deleted" if status == "paid"
    raise ArgumentError, "Due bills must be voided, not deleted" if status == "due"

    if kot_sent? && !(user&.admin? || user&.manager?)
      raise ArgumentError, "After KOT, only manager or admin can cancel this bill"
    end

    if kot_sent? && reason.to_s.strip.blank?
      raise ArgumentError, "Enter a reason to cancel after KOT"
    end

    update!(
      deleted_at: Time.current,
      cancelled_by: user,
      cancel_reason: reason.to_s.strip.presence,
      dine_in_lock_key: nil
    )
    record_edit!(
      user: user,
      action: "cancelled",
      summary: "Cancelled #{bill_number}",
      details: { reason: reason.to_s.strip.presence }
    )
  end

  def soft_delete!(user: Current.user, reason: nil)
    cancel!(user: user, reason: reason)
  end

  def recalculate_subtotal!
    update!(tax_attributes)
  end

  def item_count
    if bill_line_items.loaded?
      bill_line_items.sum(&:quantity)
    else
      bill_line_items.sum(:quantity)
    end
  end

  def pending_kot_items
    bill_line_items.select(&:kot_pending?)
  end

  def pending_kot?
    bill_line_items.any?(&:kot_pending?)
  end

  def mark_kot_sent!
    transaction do
      bill_line_items.find_each do |line|
        next unless line.kot_pending?

        line.update!(kot_sent_quantity: line.quantity)
      end
    end
  end

  def issue_kot!
    date = self.class.business_date_for
    kitchen_tickets.create!(
      kot_number: DailySequence.next!(:kot, date: date),
      service_date: date
    )
  end

  def latest_kot_number
    kitchen_tickets.maximum(:kot_number)
  end

  def status_label
    return "Cancelled" if deleted?
    return "Voided" if voided?

    status.titleize
  end

  def cashier_label
    (paid_by || opened_by)&.display_name
  end

  private

  def assert_open_for_edit!
    raise ArgumentError, "Bill is cancelled" if deleted?
    raise ArgumentError, "Bill is voided" if voided?
    raise ArgumentError, "Bill is already paid" if status == "paid"
  end

  def record_edit!(action:, summary:, details: {}, user: Current.user)
    bill_edits.create!(
      user: user,
      action: action,
      summary: summary,
      details: details.presence,
      bill_number: bill_number,
      service_date: service_date
    )
  end

  def apply_discount!(amount, reason, complementary_flag, discount_percent: nil)
    items = bill_line_items.sum(:line_total).to_d
    if ActiveModel::Type::Boolean.new.cast(complementary_flag)
      self.complementary = true
      self.discount_percent = 100
      self.discount_amount = items
      self.discount_reason = reason.to_s.strip.presence || "Complimentary / NC"
    else
      self.complementary = false
      percent = money(discount_percent.presence || 0)
      raise ArgumentError, "Discount percent must be between 0 and 100" if percent.negative? || percent > 100

      if percent.positive?
        self.discount_percent = percent
        self.discount_amount = (items * percent / 100).round(2)
      else
        discount = money(amount)
        raise ArgumentError, "Discount cannot be more than item total" if discount > items
        self.discount_percent = items.positive? ? ((discount * 100) / items).round(2) : 0
        self.discount_amount = discount
      end
      self.discount_reason = reason.to_s.strip.presence
    end
  end

  def tender_method(cash, upi, card)
    positives = [ cash.positive?, upi.positive?, card.positive? ].count(true)
    return "split" if positives > 1
    return "cash" if cash.positive?
    return "upi" if upi.positive?
    return "card" if card.positive?

    "due"
  end

  def money(value)
    BigDecimal(value.to_s.presence || "0").round(2)
  rescue ArgumentError
    BigDecimal("0")
  end

  def record_post_kot_removal!(line_item, quantity)
    quantity = quantity.to_i
    return if quantity <= 0

    bill_removals.create!(
      menu_item_id: line_item.menu_item_id,
      item_name: line_item.item_name,
      unit_price: line_item.unit_price,
      quantity: quantity,
      line_total: line_item.unit_price.to_d * quantity,
      removed_at: Time.current
    )
  end

  def assign_defaults
    self.opened_at ||= Time.current
    self.service_date ||= self.class.business_date_for(opened_at)
    self.status ||= "active"
    self.opened_by ||= Current.user
    self.bill_number ||= DailySequence.next!(:bill, date: service_date).to_s
    apply_tax_amounts
  end

  def assign_dine_in_lock_key
    self.dine_in_lock_key = dine_in_lock_key_value
  end

  def dine_in_lock_key_value
    return nil unless open_on_table?
    return nil if takeaway_order?

    dining_table_id
  end

  def tax_attributes(items_subtotal = bill_line_items.sum(:line_total))
    items = items_subtotal.to_d
    percent = discount_percent.to_d
    discount = if complementary?
      items
    elsif percent.positive?
      (items * percent / 100).round(2)
    else
      [ discount_amount.to_d, items ].min
    end
    taxable = complementary? ? BigDecimal("0") : [ items - discount, 0 ].max
    cgst = (taxable * CGST_RATE).round(2)
    sgst = (taxable * SGST_RATE).round(2)
    {
      subtotal: items,
      discount_amount: discount,
      cgst_amount: cgst,
      sgst_amount: sgst,
      total: taxable + cgst + sgst
    }
  end

  def apply_tax_amounts
    tax_attributes.each { |key, value| self[key] = value }
  end

  def only_one_active_bill_per_table
    exists = Bill.open_on_table.where(dining_table_id: dining_table_id)
    exists = exists.where.not(id: id) if persisted?
    errors.add(:dining_table, "already has an active bill") if exists.exists?
  end
end
