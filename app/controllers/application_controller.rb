class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :authenticate_user!, unless: :devise_controller?
  before_action :set_current_user

  helper_method :signed_in_home_path

  # Turbo requires 303 See Other after non-GET so flash notices render on the next page.
  def redirect_to(options = {}, response_options = {})
    if mutating_request? && !response_options.key?(:status)
      response_options = response_options.merge(status: :see_other)
    end
    super
  end

  private

  def set_current_user
    Current.user = current_user
  end

  def after_sign_in_path_for(resource)
    signed_in_home_path(resource)
  end

  def signed_in_home_path(user = current_user)
    return bills_path unless user&.admin?

    grocery_path
  end

  def require_admin!
    authorize_roles!(:admin)
  end

  def require_bill_access!
    authorize_roles!(:admin, :manager, :staff)
  end

  def require_takeaway_access!
    authorize_roles!(:admin, :manager)
  end

  def authorize_roles!(*roles)
    return if current_user&.role.in?(roles.map(&:to_s))

    redirect_to signed_in_home_path, alert: "You don't have access to that page."
  end

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
