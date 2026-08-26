class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # Reading the signed-in user in a filter is enough for Warden to authenticate
  # from the posted credentials, which is what the sessions tests rely on.
  before_action :track_signed_in_user

  private

  def track_signed_in_user
    @signed_in_user = current_user
  end
end
