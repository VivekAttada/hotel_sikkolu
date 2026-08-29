class Bill < ApplicationRecord
  belongs_to :dining_table
  has_many :bill_line_items, dependent: :destroy
  has_many :bill_removals, dependent: :destroy

  STATUSES = %w[active paid].freeze
  PAYMENT_METHODS = %w[cash upi card].freeze

  validates :bill_number, :status, :opened_at, presence: true
  validates :bill_number, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }, allow_nil: true
  validate :only_one_active_bill_per_table, if: -> { active? && !deleted? && dining_table_id.present? && !takeaway_order? }

  scope :kept, -> { where(deleted_at: nil) }
  scope :trashed, -> { where.not(deleted_at: nil) }
  scope :active, -> { kept.where(status: "active") }
  scope :paid, -> { kept.where(status: "paid") }
  scope :takeaway_orders, -> {
    joins(:dining_table).where(dining_tables: { name: DiningTable::TAKEAWAY_NAME })
  }
  scope :active_takeaways, -> { active.takeaway_orders.order(opened_at: :desc) }
  scope :for_day, ->(date) {
    paid.where(paid_at: date.beginning_of_day..date.end_of_day)
  }
  scope :deleted_on, ->(date) {
    trashed.where(deleted_at: date.beginning_of_day..date.end_of_day)
  }
  scope :recent_first, -> { order(Arel.sql("COALESCE(paid_at, opened_at) DESC")) }
  scope :recently_deleted, -> { order(deleted_at: :desc) }

  before_validation :assign_defaults, on: :create

  def active?
    status == "active" && !deleted?
  end

  def paid?
    status == "paid" && !deleted?
  end

  def deleted?
    deleted_at.present?
  end

  def self.open_for!(dining_table)
    existing = dining_table.active_bill
    return existing if existing

    create!(dining_table: dining_table)
  end

  def self.create_takeaway!
    create!(dining_table: DiningTable.takeaway!)
  end

  def takeaway_order?
    dining_table&.takeaway?
  end

  def add_menu_item!(menu_item, quantity: 1)
    raise ArgumentError, "Bill is deleted" if deleted?
    raise ArgumentError, "Bill is already paid" if status == "paid"

    quantity = quantity.to_i
    raise ArgumentError, "Quantity must be at least 1" if quantity < 1

    transaction do
      line = bill_line_items.find_or_initialize_by(menu_item_id: menu_item.id)
      line.item_name = menu_item.name
      line.unit_price = menu_item.price if line.new_record?
      line.quantity = line.new_record? ? quantity : line.quantity + quantity
      line.recalculate_total!
      line.save!
      recalculate_subtotal!
    end
  end

  def update_line_quantity!(line_item, quantity)
    raise ArgumentError, "Bill is deleted" if deleted?
    raise ArgumentError, "Bill is already paid" if status == "paid"

    quantity = quantity.to_i
    transaction do
      if quantity <= 0
        record_post_kot_removal!(line_item, line_item.kot_sent_quantity.to_i)
        line_item.destroy!
      else
        removed_from_kot = [ line_item.kot_sent_quantity.to_i - quantity, 0 ].max
        record_post_kot_removal!(line_item, removed_from_kot)
        line_item.update!(quantity: quantity)
        line_item.recalculate_total!
        line_item.save!
      end
      recalculate_subtotal!
    end
  end

  def remove_line_item!(line_item)
    raise ArgumentError, "Bill is deleted" if deleted?
    raise ArgumentError, "Bill is already paid" if status == "paid"

    transaction do
      record_post_kot_removal!(line_item, line_item.kot_sent_quantity.to_i)
      line_item.destroy!
      recalculate_subtotal!
    end
  end

  def post_kot_removals?
    bill_removals.exists?
  end

  def mark_paid!(payment_method:, removal_reason: nil)
    raise ArgumentError, "Bill is deleted" if deleted?
    raise ArgumentError, "Bill is already paid" if status == "paid"
    raise ArgumentError, "Add at least one item before payment" if bill_line_items.empty?

    method = payment_method.to_s.strip.downcase
    raise ArgumentError, "Select payment method: Cash, UPI, or Card" unless PAYMENT_METHODS.include?(method)

    reason = removal_reason.to_s.strip
    if post_kot_removals? && reason.blank?
      raise ArgumentError, "Enter a reason for items removed after KOT"
    end

    transaction do
      if post_kot_removals?
        bill_removals.where(reason: [ nil, "" ]).update_all(reason: reason, updated_at: Time.current)
      end

      update!(
        status: "paid",
        paid_at: Time.current,
        payment_method: method,
        subtotal: bill_line_items.sum(:line_total)
      )
    end
  end

  def payment_method_label
    return "—" if payment_method.blank?

    payment_method.upcase == "UPI" ? "UPI" : payment_method.titleize
  end

  def soft_delete!
    raise ArgumentError, "Bill is already deleted" if deleted?

    update!(deleted_at: Time.current)
  end

  def recalculate_subtotal!
    update!(subtotal: bill_line_items.sum(:line_total))
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

  def status_label
    return "Deleted" if deleted?

    status.titleize
  end

  private

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
    self.status ||= "active"
    self.bill_number ||= generate_bill_number
  end

  def generate_bill_number
    "HS-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
  end

  def only_one_active_bill_per_table
    exists = Bill.active.where(dining_table_id: dining_table_id)
    exists = exists.where.not(id: id) if persisted?
    errors.add(:dining_table, "already has an active bill") if exists.exists?
  end
end
