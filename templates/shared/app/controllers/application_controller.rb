class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # Host applications routinely resolve the signed-in user in a callback, such as
  # assigning Current.user or PaperTrail's whodunnit. Devise permits
  # authentication straight from the posted credentials on create, so this makes
  # Warden sign the visitor in unless Turnstile has been settled first.
  before_action :track_signed_in_user

  private

  def track_signed_in_user
    @signed_in_user = current_user
  end
end
