class DiningTable < ApplicationRecord
  TAKEAWAY_NAME = "Take Away".freeze
  SPLIT_SUFFIXES = %w[A B].freeze

  belongs_to :parent_dining_table, class_name: "DiningTable", optional: true
  has_many :split_children, class_name: "DiningTable", foreign_key: :parent_dining_table_id, dependent: :destroy, inverse_of: :parent_dining_table
  has_many :bills, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  scope :ordered, -> { where(active: true).where.not(name: TAKEAWAY_NAME).order(:position, :name, :id) }

  def self.takeaway!
    table = find_or_initialize_by(name: TAKEAWAY_NAME)
    table.position = 999 if table.new_record?
    table.active = true
    table.save!
    table
  end

  def takeaway?
    name == TAKEAWAY_NAME
  end

  def display_name
    takeaway? ? "Take Away" : name
  end

  def split_child?
    parent_dining_table_id.present?
  end

  def currently_split?
    !active? && split_children.where(active: true).exists?
  end

  def can_split?
    return false if takeaway? || split_child? || currently_split?
    return false if active_bill&.item_count.to_i.positive?
    return false if active_split_names.any? { |n| DiningTable.where(name: n, active: true).exists? }

    true
  end

  def can_merge?
    return false unless currently_split? || (split_child? && parent_dining_table&.currently_split?)

    parent = split_child? ? parent_dining_table : self
    children = parent.split_children.where(active: true)
    children.size >= 2 && children.none?(&:occupied?)
  end

  def split!
    raise ArgumentError, "Take Away cannot be split" if takeaway?
    raise ArgumentError, "This is already a split table" if split_child?
    raise ArgumentError, "Table is already split" if currently_split?
    raise ArgumentError, "Table cannot be split right now" unless can_split?

    transaction do
      existing_bill = active_bill
      SPLIT_SUFFIXES.each_with_index do |suffix, index|
        child = split_children.find_or_initialize_by(name: "#{name}#{suffix}")
        child.position = (position * 10) + index
        child.active = true
        child.parent_dining_table = self
        child.save!
      end
      update!(active: false)
      discard_empty_bill!(existing_bill)
    end

    split_children.where(active: true).order(:position, :name)
  end

  def merge!
    parent = split_child? ? parent_dining_table : self
    raise ArgumentError, "Table is not split" unless parent
    raise ArgumentError, "Both split sides must be free before merging" unless parent.can_merge?

    transaction do
      parent.split_children.where(active: true).find_each do |child|
        child.update!(active: false)
      end
      parent.update!(active: true)
    end

    parent
  end

  def collapse_split_if_settled!
    parent = split_child? ? parent_dining_table : self
    return unless parent&.currently_split?

    parent.split_children.where(active: true).find_each do |child|
      child.discard_empty_active_bill!
      child.update!(active: false) unless child.reload.active_bill.present?
    end

    remaining = parent.split_children.where(active: true)
    return if remaining.any? { |child| child.active_bill.present? }

    remaining.find_each { |child| child.update!(active: false) }
    parent.update!(active: true)
    parent
  end

  def active_bill
    bills.open_on_table.order(opened_at: :desc).first
  end

  def occupied?
    active_bill.present?
  end

  def discard_empty_active_bill!
    discard_empty_bill!(active_bill)
  end

  private

  def discard_empty_bill!(bill)
    return unless bill&.active?
    return if bill.bill_line_items.exists?

    bill.bill_line_items.delete_all
    bill.kitchen_tickets.delete_all if bill.respond_to?(:kitchen_tickets)
    bill.delete
  end

  def active_split_names
    SPLIT_SUFFIXES.map { |suffix| "#{name}#{suffix}" }
  end
end
