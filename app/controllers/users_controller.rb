class UsersController < ApplicationController
  include Pagy::Backend
  before_action :authenticate_user!

  def dashboard
    @pagy, @zines = pagy(current_user.zines.includes(:category).order(created_at: :desc), items: 12)
  end
end