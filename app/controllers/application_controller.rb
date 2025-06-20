class ApplicationController < ActionController::Base
  include Pagy::Frontend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protected

  def after_sign_in_path_for(resource)
    dashboard_path
  end
end
