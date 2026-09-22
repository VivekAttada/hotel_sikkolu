class SettingsController < ApplicationController
  before_action :require_admin!

  def update
    number = params[:whatsapp_number].to_s.strip
    digits = number.gsub(/\D/, "")

    if digits.present? && digits.length < 10
      redirect_to settings_path, alert: "Enter a valid WhatsApp number with country code (e.g. 919876543210)."
      return
    end

    AppSetting.whatsapp_number = number
    redirect_to settings_path, notice: digits.present? ? "WhatsApp number saved." : "WhatsApp number cleared."
  end

  def send_email_report
    recipients = ResendDailyReport.deliver!(date: Bill.business_date_for)
    redirect_to settings_path, notice: "Daily report emailed to #{recipients.join(', ')}."
  rescue ResendDailyReport::Error => e
    redirect_to settings_path, alert: e.message
  end
end
