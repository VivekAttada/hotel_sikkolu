require "net/http"
require "json"

class ResendDailyReport
  class Error < StandardError; end

  API_URL = URI("https://api.resend.com/emails")

  RECIPIENTS = [
    "potnuruhimabindu3@gmail.com",
    "anemhari18@gmail.com",
    "vivek.attada8@gmail.com"
  ].freeze

  def self.configured?
    ENV["RESEND_API_KEY"].to_s.strip.present?
  end

  def self.recipients
    RECIPIENTS
  end

  def self.deliver!(date: Date.current)
    new(date: date).deliver!
  end

  def initialize(date: Date.current)
    @date = date
    @api_key = ENV["RESEND_API_KEY"].to_s.strip
    @from = ENV.fetch("RESEND_FROM_EMAIL", "Hotel Sikkolu <reports@updates.sikkolu.com>")
  end

  def deliver!
    raise Error, "Add RESEND_API_KEY to your environment before sending email." if @api_key.blank?

    report = DailyReport.new(@date)
    payload = {
      from: @from,
      to: RECIPIENTS.dup,
      subject: "Hotel Sikkolu daily report — #{@date.strftime('%d %b %Y')}",
      text: report.body,
      html: report.html_body
    }

    response = post_json(payload)
    unless response.is_a?(Net::HTTPSuccess)
      message = parse_error(response) || "Resend returned HTTP #{response.code}"
      raise Error, message
    end

    RECIPIENTS
  end

  private

  def post_json(payload)
    http = Net::HTTP.new(API_URL.host, API_URL.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 20

    request = Net::HTTP::Post.new(API_URL)
    request["Authorization"] = "Bearer #{@api_key}"
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(payload)
    http.request(request)
  end

  def parse_error(response)
    data = JSON.parse(response.body)
    data["message"].presence || data.dig("error", "message")
  rescue JSON::ParserError
    nil
  end
end
