class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  private

  def parse_date(value)
    return if value.blank?

    Date.parse(value)
  rescue ArgumentError
    nil
  end
end
