class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :authenticate_user!, unless: :devise_controller?

  # Turbo requires 303 See Other after non-GET so flash notices render on the next page.
  def redirect_to(options = {}, response_options = {})
    if mutating_request? && !response_options.key?(:status)
      response_options = response_options.merge(status: :see_other)
    end
    super
  end

  private

  def mutating_request?
    request.post? || request.patch? || request.put? || request.delete?
  end

  def parse_date(value)
    return if value.blank?

    Date.parse(value)
  rescue ArgumentError
    nil
  end
end
