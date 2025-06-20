class AdminController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!
  before_action :authorize_admin!

  def index
    @pending_count = Zine.pending_moderation.count
    @total_count = Zine.count
    @approved_count = Zine.approved.count

    # Show pending zines first, then approved ones
    @pagy, @zines = pagy(Zine.includes(:category, :user).order(:pending_moderation, created_at: :desc), items: 20)
  end

  def approve
    @zine = Zine.find(params[:id])
    @zine.approve!
    redirect_to admin_path, notice: "Zine '#{@zine.title}' has been approved."
  end

  def reject
    @zine = Zine.find(params[:id])
    title = @zine.title
    @zine.reject!
    redirect_to admin_path, notice: "Zine '#{title}' has been rejected and deleted."
  end

  def destroy
    @zine = Zine.find(params[:id])
    title = @zine.title
    @zine.destroy
    redirect_to admin_path, notice: "Zine '#{title}' has been deleted."
  end

  private

  def authorize_admin!
    unless current_user.admin?
      redirect_to root_path, alert: 'Access denied. Admin privileges required.'
    end
  end
end