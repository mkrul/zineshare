class ZinesController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_zine, only: [:show, :edit, :update, :destroy]
  before_action :authorize_zine_owner, only: [:edit, :update, :destroy]

  def index
    @categories = Category.all.order(:name)

    # Build base query with all zines (removed approval filtering)
    zines_query = Zine.includes(:category)

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
    Rails.logger.info "=== ZINE UPLOAD START ==="
    Rails.logger.info "User: #{current_user.id} (#{current_user.email})"
    Rails.logger.info "Params received: #{params.inspect}"
    Rails.logger.info "Zine params: #{zine_params.inspect}"

    # Log file upload details
    if params[:zine] && params[:zine][:pdf_file]
      pdf_file_param = params[:zine][:pdf_file]
      Rails.logger.info "PDF file param present: #{pdf_file_param.class}"
      Rails.logger.info "PDF file original filename: #{pdf_file_param.original_filename}" if pdf_file_param.respond_to?(:original_filename)
      Rails.logger.info "PDF file content type: #{pdf_file_param.content_type}" if pdf_file_param.respond_to?(:content_type)
      Rails.logger.info "PDF file size: #{pdf_file_param.size} bytes" if pdf_file_param.respond_to?(:size)
    else
      Rails.logger.warn "No PDF file parameter found in params"
    end

    @zine = current_user.zines.build(zine_params)
    @categories = Category.all.order(:name)

    Rails.logger.info "Zine built with attributes: #{@zine.attributes.inspect}"
    Rails.logger.info "PDF file attached?: #{@zine.pdf_file.attached?}"

    if @zine.save
      Rails.logger.info "Zine saved successfully with ID: #{@zine.id}"
      Rails.logger.info "PDF file attached after save?: #{@zine.pdf_file.attached?}"

      # Check if Dropbox upload was successful (in production)
      if Rails.env.production? && @zine.file_id.blank?
        Rails.logger.error "Dropbox upload failed - no file_id present"
        flash[:alert] = 'Zine was uploaded but there was an issue with remote storage. Please try again or contact support.'
        render :new, status: :unprocessable_entity
      else
        success_message = if Rails.env.test?
          'Zine was successfully uploaded.'
        else
          'Zine was successfully uploaded to secure storage.'
        end
        Rails.logger.info "Zine upload completed successfully"
        redirect_to @zine, notice: success_message
      end
    else
      Rails.logger.error "Zine save failed with errors: #{@zine.errors.full_messages.join(', ')}"
      Rails.logger.error "Validation errors: #{@zine.errors.details.inspect}"
      render :new, status: :unprocessable_entity
    end

    Rails.logger.info "=== ZINE UPLOAD END ==="
  end

  def edit
  end

  def update
    old_file_id = @zine.file_id
    pdf_was_replaced = zine_params[:pdf_file].present?

    if @zine.update(zine_params)
      if pdf_was_replaced
        # Delete old file from Dropbox if it exists
        if old_file_id.present?
          begin
            @zine.send(:dropbox_service).delete_file(old_file_id)
            Rails.logger.info "Deleted old Dropbox file #{old_file_id} for zine #{@zine.id}"
          rescue => e
            Rails.logger.error "Failed to delete old Dropbox file: #{e.message}"
          end
        end

        # Trigger new upload and thumbnail generation
        @zine.send(:upload_to_dropbox) unless Rails.env.test?
        @zine.send(:generate_thumbnail)
      end

      redirect_to @zine, notice: 'Zine was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    Rails.logger.info "=== ZINE DELETE START ==="
    Rails.logger.info "User: #{current_user.id} (#{current_user.email})"
    Rails.logger.info "Zine ID: #{@zine.id}"
    Rails.logger.info "Zine title: #{@zine.title}"
    Rails.logger.info "PDF file attached?: #{@zine.pdf_file.attached?}"
    Rails.logger.info "Dropbox file ID: #{@zine.file_id}"
    Rails.logger.info "Zine owner: #{@zine.user_id}"
    Rails.logger.info "Current user: #{current_user.id}"
    Rails.logger.info "User authorized?: #{current_user == @zine.user}"

    zine_id = @zine.id

    begin
      Rails.logger.info "Attempting to destroy zine"
      if @zine.destroy
        Rails.logger.info "Zine destroyed successfully"

        respond_to do |format|
          format.html { redirect_to dashboard_path, notice: 'Your zine has been deleted.' }
          format.turbo_stream {
            render turbo_stream: [
              turbo_stream.remove("zine_#{zine_id}"),
              turbo_stream.update("flash_messages", partial: "shared/flash", locals: {
                notice: "Your zine has been deleted."
              })
            ]
          }
        end
      else
        Rails.logger.error "Failed to destroy zine: #{@zine.errors.full_messages.join(', ')}"

        respond_to do |format|
          format.html { redirect_to @zine, alert: 'Failed to delete zine. Please try again.' }
          format.turbo_stream {
            render turbo_stream: turbo_stream.update("flash_messages", partial: "shared/flash", locals: {
              alert: "Failed to delete zine. Please try again."
            })
          }
        end
      end
    rescue => e
      Rails.logger.error "Exception during zine destruction: #{e.class} - #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(5).join('\n')}"

      respond_to do |format|
        format.html { redirect_to @zine, alert: 'An error occurred while deleting the zine. Please try again.' }
        format.turbo_stream {
          render turbo_stream: turbo_stream.update("flash_messages", partial: "shared/flash", locals: {
            alert: "An error occurred while deleting the zine. Please try again."
          })
        }
      end
    end

    Rails.logger.info "=== ZINE DELETE END ==="
  end

  private

  def set_zine
    @zine = Zine.find(params[:id])
  end

  def zine_params
    permitted_params = params.require(:zine).permit(:title, :created_by, :category_id, :pdf_file)
    Rails.logger.info "Permitted zine params: #{permitted_params.inspect}"

    if permitted_params[:pdf_file]
      Rails.logger.info "PDF file param details:"
      Rails.logger.info "- Class: #{permitted_params[:pdf_file].class}"
      Rails.logger.info "- Original filename: #{permitted_params[:pdf_file].original_filename}" if permitted_params[:pdf_file].respond_to?(:original_filename)
      Rails.logger.info "- Content type: #{permitted_params[:pdf_file].content_type}" if permitted_params[:pdf_file].respond_to?(:content_type)
      Rails.logger.info "- Size: #{permitted_params[:pdf_file].size} bytes" if permitted_params[:pdf_file].respond_to?(:size)
    else
      Rails.logger.warn "No PDF file in permitted params"
    end

    permitted_params
  end

  def authorize_zine_owner
    unless current_user == @zine.user
      redirect_to dashboard_path, alert: 'You are not authorized to perform this action.'
    end
  end
end
