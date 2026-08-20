class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :authenticate_user!, unless: :devise_controller?

  private

  def parse_date(value)
    return if value.blank?

    Date.parse(value)
  rescue ArgumentError
    nil
  end
end
