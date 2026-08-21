class Bill < ApplicationRecord
  belongs_to :dining_table
  has_many :bill_line_items, dependent: :destroy

  STATUSES = %w[active paid].freeze

  validates :bill_number, :status, :opened_at, presence: true
  validates :bill_number, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validate :only_one_active_bill_per_table, if: -> { active? && !deleted? && dining_table_id.present? }

  scope :kept, -> { where(deleted_at: nil) }
  scope :trashed, -> { where.not(deleted_at: nil) }
  scope :active, -> { kept.where(status: "active") }
  scope :paid, -> { kept.where(status: "paid") }
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
        line_item.destroy!
      else
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
      line_item.destroy!
      recalculate_subtotal!
    end
  end

  def mark_paid!
    raise ArgumentError, "Bill is deleted" if deleted?
    raise ArgumentError, "Bill is already paid" if status == "paid"
    raise ArgumentError, "Add at least one item before payment" if bill_line_items.empty?

    update!(status: "paid", paid_at: Time.current, subtotal: bill_line_items.sum(:line_total))
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
