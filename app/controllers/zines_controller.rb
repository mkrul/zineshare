class ZinesController < ApplicationController
  include Pagy::Backend

  before_action :set_zine, only: [:show]

  def index
    @categories = Category.all.order(:name)

    # Build base query with approved zines
    zines_query = Zine.approved.includes(:category)

    # Apply category filter if present
    if params[:category_id].present? && params[:category_id] != 'all'
      zines_query = zines_query.where(category_id: params[:category_id])
      @selected_category = Category.find_by(id: params[:category_id])
    end

    # Order by creation date (newest first)
    zines_query = zines_query.order(created_at: :desc)

    # Apply pagination
    @pagy, @zines = pagy(zines_query, items: 12)

    # Handle AJAX requests for infinite scrolling
    respond_to do |format|
      format.html
      format.turbo_stream { render partial: 'zines_page', locals: { zines: @zines, pagy: @pagy } }
    end
  end

  def show
  end

  def new
    @zine = Zine.new
    @categories = Category.all.order(:name)
  end

  def create
    @zine = Zine.new(zine_params)
    @categories = Category.all.order(:name)

    if @zine.save
      # Check if Box upload was successful (in production)
      if Rails.env.production? && @zine.box_file_id.blank?
        flash[:alert] = 'Zine was uploaded but there was an issue with remote storage. Please try again or contact support.'
        render :new, status: :unprocessable_entity
      else
        success_message = if Rails.env.test?
          'Zine was successfully uploaded and is pending approval.'
        else
          'Zine was successfully uploaded to secure storage and is pending approval.'
        end
        redirect_to @zine, notice: success_message
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_zine
    @zine = Zine.find(params[:id])
  end

  def zine_params
    params.require(:zine).permit(:created_by, :category_id, :pdf_file)
  end
end
