class User < ApplicationRecord
  ROLES = %w[admin manager staff].freeze

  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :validatable,
         :lockable,
         :timeoutable,
         authentication_keys: [ :email ]

  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :role, presence: true, inclusion: { in: ROLES }

  before_validation :assign_username_from_email, on: :create
  before_validation :assign_name_from_role, on: :create

  has_many :opened_bills, class_name: "Bill", foreign_key: :opened_by_id, dependent: :nullify, inverse_of: :opened_by
  has_many :paid_bills, class_name: "Bill", foreign_key: :paid_by_id, dependent: :nullify, inverse_of: :paid_by
  has_many :bill_edits, dependent: :nullify

  def admin?
    role == "admin"
  end

  def manager?
    role == "manager"
  end

  def staff?
    role == "staff"
  end

  def can_access_tab?(tab)
    case tab.to_s
    when "bills" then admin? || manager? || staff?
    when "paid_bills" then admin? || manager?
    when "takeaway" then admin? || manager?
    when "grocery", "checklist", "payments", "settings", "bill_edits", "cancelled_kots" then admin?
    else false
    end
  end

  def can_view_paid_bills?
    admin? || manager?
  end

  def home_path_key
    admin? ? :grocery : :bills
  end

  def role_label
    role.to_s.titleize
  end

  def display_name
    name.presence || username.presence || email.to_s.split("@").first
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:email) || conditions.delete(:username) || conditions.delete(:login)
    value = login.to_s.downcase.strip
    where(conditions).where("lower(email) = :value OR lower(username) = :value", value: value).first
  end

  private

  def assign_username_from_email
    return if username.present? || email.blank?

    self.username = email.to_s.split("@").first.to_s.downcase
  end

  def assign_name_from_role
    self.name = role_label if name.blank? && role.present?
  end
end
