class AppSetting < ApplicationRecord
  WHATSAPP_NUMBER_KEY = "whatsapp_number".freeze
  REPORT_EMAIL_KEY = "report_email".freeze

  validates :key, presence: true, uniqueness: true

  def self.get(key)
    find_by(key: key)&.value.to_s
  end

  def self.set(key, value)
    record = find_or_initialize_by(key: key)
    record.value = value.to_s.strip
    record.save!
    record.value
  end

  def self.whatsapp_number
    get(WHATSAPP_NUMBER_KEY)
  end

  def self.whatsapp_number=(value)
    set(WHATSAPP_NUMBER_KEY, value)
  end

  def self.report_email
    get(REPORT_EMAIL_KEY)
  end

  def self.report_email=(value)
    set(REPORT_EMAIL_KEY, value)
  end

  # Digits only, with country code. 10-digit Indian numbers get 91 prefix.
  def self.normalized_whatsapp_number(raw = whatsapp_number)
    digits = raw.to_s.gsub(/\D/, "")
    return "" if digits.blank?
    return "91#{digits}" if digits.length == 10

    digits
  end
end
