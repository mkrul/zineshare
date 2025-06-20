class ZinesController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_zine, only: [:show, :edit, :update, :destroy]
  before_action :authorize_zine_owner, only: [:edit, :update, :destroy]

  def index
    @categories = Category.all.order(:name)

    # Build base query with approved zines only
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
    @zine = current_user.zines.build(zine_params)
    @categories = Category.all.order(:name)

    if @zine.save
      # Check if Box upload was successful (in production)
      if Rails.env.production? && @zine.box_file_id.blank?
        flash[:alert] = 'Zine was uploaded but there was an issue with remote storage. Please try again or contact support.'
        render :new, status: :unprocessable_entity
      else
        success_message = if Rails.env.test?
          'Zine was successfully uploaded.'
        else
          'Zine was successfully uploaded to secure storage.'
        end
        redirect_to @zine, notice: success_message
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    old_box_file_id = @zine.box_file_id
    pdf_was_replaced = zine_params[:pdf_file].present?

    if @zine.update(zine_params)
      if pdf_was_replaced
        # Delete old file from Box if it exists
        if old_box_file_id.present?
          begin
            @zine.send(:box_service).delete_file(old_box_file_id)
            Rails.logger.info "Deleted old Box file #{old_box_file_id} for zine #{@zine.id}"
          rescue => e
            Rails.logger.error "Failed to delete old Box file: #{e.message}"
          end
        end

        # Trigger new upload and thumbnail generation
        @zine.send(:upload_to_box) unless Rails.env.test?
        @zine.send(:generate_thumbnail)
      end

      redirect_to @zine, notice: 'Zine was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @zine.destroy
    redirect_to dashboard_path, notice: 'Your zine has been deleted.'
  end

  private

  def set_zine
    @zine = Zine.find(params[:id])
  end

  def zine_params
    params.require(:zine).permit(:title, :created_by, :category_id, :pdf_file)
  end

  def authorize_zine_owner
    unless current_user == @zine.user
      redirect_to dashboard_path, alert: 'You are not authorized to perform this action.'
    end
  end
end
