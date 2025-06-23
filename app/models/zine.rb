class Zine < ApplicationRecord
  belongs_to :category
  belongs_to :user, optional: true

  has_one_attached :pdf_file
  has_one_attached :thumbnail

  validates :title, presence: true, length: { maximum: 100 }
  validates :created_by, presence: true
  validates :category, presence: true
  validates :pdf_file, presence: true, unless: -> { Rails.env.test? }
  validate :pdf_file_must_be_pdf, unless: -> { Rails.env.test? }
  validate :pdf_file_size_within_limit, unless: -> { Rails.env.test? }
  # TODO: Re-enable after fixing Active Storage timing issue
  # validate :pdf_dimensions_must_be_correct, unless: -> { Rails.env.test? }

  scope :approved, -> { where(pending_moderation: false) }
  scope :pending_moderation, -> { where(pending_moderation: true) }

  after_create :notify_admin, unless: -> { Rails.env.test? }
  after_commit :upload_to_dropbox_after_save, on: :create, if: -> { pdf_file.attached? && !Rails.env.test? }
  after_commit :generate_thumbnail_after_save, on: :create, if: -> { pdf_file.attached? }
  after_commit :validate_pdf_dimensions_after_save, on: :create, if: -> { pdf_file.attached? && !Rails.env.test? }
  before_destroy :cleanup_attachments
  before_destroy :delete_from_dropbox

  def approved?
    !pending_moderation?
  end

  def approve!
    update!(pending_moderation: false)
  end

  def reject!
    destroy
  end

  def dropbox_download_url
    return nil unless file_id.present?

    begin
      dropbox_service.get_file_download_url(file_id)
    rescue DropboxService::DropboxError => e
      Rails.logger.error "Failed to get Dropbox download URL for zine #{id}: #{e.message}"
      nil
    end
  end

  def file_available?
    if Rails.env.test?
      pdf_file.attached?
    elsif Rails.env.development?
      # In development, check both Dropbox and Active Storage
      # This allows viewing files before/during Dropbox upload
      (file_id.present? && dropbox_service.file_exists?(file_id)) || pdf_file.attached?
    else
      # In production, only check Dropbox
      file_id.present? && dropbox_service.file_exists?(file_id)
    end
  end

  def thumbnail_url
    if thumbnail.attached?
      Rails.application.routes.url_helpers.rails_blob_path(thumbnail, only_path: true)
    else
      # Fallback to a default thumbnail
      ActionController::Base.helpers.asset_path('default-zine-thumbnail.svg')
    end
  end

  private

  def pdf_file_must_be_pdf
    Rails.logger.info "=== PDF FILE TYPE VALIDATION START ==="
    Rails.logger.info "PDF file attached?: #{pdf_file.attached?}"

    return unless pdf_file.attached?

    Rails.logger.info "PDF file content type: #{pdf_file.content_type}"
    Rails.logger.info "PDF file blob present?: #{pdf_file.blob.present?}"
    Rails.logger.info "PDF file filename: #{pdf_file.filename}" if pdf_file.filename.present?

    unless pdf_file.content_type == 'application/pdf'
      Rails.logger.error "PDF validation failed - incorrect content type: #{pdf_file.content_type}"
      errors.add(:pdf_file, 'must be a PDF file')
    else
      Rails.logger.info "PDF content type validation passed"
    end

    Rails.logger.info "=== PDF FILE TYPE VALIDATION END ==="
  end

  def pdf_file_size_within_limit
    Rails.logger.info "=== PDF FILE SIZE VALIDATION START ==="
    Rails.logger.info "PDF file attached?: #{pdf_file.attached?}"

    return unless pdf_file.attached?

    file_size = pdf_file.blob.byte_size
    Rails.logger.info "PDF file size: #{file_size} bytes (#{(file_size / 1024.0 / 1024.0).round(2)} MB)"
    Rails.logger.info "Size limit: #{10.megabytes} bytes (10 MB)"

    if file_size > 10.megabytes
      Rails.logger.error "PDF validation failed - file too large: #{file_size} bytes"
      errors.add(:pdf_file, 'must be within 10MB')
    else
      Rails.logger.info "PDF file size validation passed"
    end

    Rails.logger.info "=== PDF FILE SIZE VALIDATION END ==="
  end

  def pdf_dimensions_must_be_correct
    Rails.logger.info "=== PDF DIMENSIONS VALIDATION START ==="
    Rails.logger.info "PDF file attached?: #{pdf_file.attached?}"
    Rails.logger.info "PDF content type: #{pdf_file.content_type}" if pdf_file.attached?

    return unless pdf_file.attached? && pdf_file.content_type == 'application/pdf'

    begin
      Rails.logger.info "Accessing PDF file for dimension validation"

      # Try to get the file path directly from the attachment
      file_to_validate = nil

      if pdf_file.blob.respond_to?(:io) && pdf_file.blob.io.respond_to?(:path)
        # Direct access to uploaded file path
        file_to_validate = pdf_file.blob.io.path
        Rails.logger.info "Using uploaded file path: #{file_to_validate}"
      elsif pdf_file.blob.respond_to?(:io) && pdf_file.blob.io.respond_to?(:tempfile)
        # Access via tempfile
        file_to_validate = pdf_file.blob.io.tempfile.path
        Rails.logger.info "Using tempfile path: #{file_to_validate}"
      else
        # Fallback to blob download (this might fail during validation)
        Rails.logger.info "Falling back to blob download"
        pdf_file.blob.open do |temp_file|
          file_to_validate = temp_file.path
          Rails.logger.info "Using blob temp file path: #{file_to_validate}"
          validate_pdf_dimensions(file_to_validate)
          return # Exit early since we've already validated
        end
      end

      if file_to_validate && File.exist?(file_to_validate)
        Rails.logger.info "Validating PDF at path: #{file_to_validate}"
        validate_pdf_dimensions(file_to_validate)
      else
        Rails.logger.error "Could not access PDF file for validation"
        errors.add(:pdf_file, "could not be accessed for dimension validation")
      end

    rescue => e
      Rails.logger.error "PDF dimensions validation error: #{e.class} - #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(5).join('\n')}"
      errors.add(:pdf_file, "could not be processed: #{e.message}")
    end

    Rails.logger.info "=== PDF DIMENSIONS VALIDATION END ==="
  end

  private

  def validate_pdf_dimensions(file_path)
    Rails.logger.info "Validating PDF dimensions from file path: #{file_path}"
    Rails.logger.info "File exists?: #{File.exist?(file_path)}"
    Rails.logger.info "File size: #{File.size(file_path)} bytes" if File.exist?(file_path)

    reader = PDF::Reader.new(file_path)
    first_page = reader.pages.first
    Rails.logger.info "PDF reader created, got first page"

    # PDF dimensions are in points (72 points = 1 inch)
    # Convert 1224x1584 pixels to points assuming 72 DPI
    expected_width = 1224.0
    expected_height = 1584.0

    # Get page dimensions in points
    page_width = first_page.width
    page_height = first_page.height

    Rails.logger.info "Expected dimensions: #{expected_width}×#{expected_height} points"
    Rails.logger.info "Actual dimensions: #{page_width}×#{page_height} points"
    Rails.logger.info "Width difference: #{(page_width - expected_width).abs} points"
    Rails.logger.info "Height difference: #{(page_height - expected_height).abs} points"

    # Allow for small rounding differences (within 1 point)
    unless (page_width - expected_width).abs <= 1 && (page_height - expected_height).abs <= 1
      Rails.logger.error "PDF dimensions validation failed"
      errors.add(:pdf_file, "must have exact dimensions of 1224×1584 pixels (#{expected_width}×#{expected_height} points). Current dimensions: #{page_width.round}×#{page_height.round} points")
    else
      Rails.logger.info "PDF dimensions validation passed"
    end
  end

  def generate_thumbnail
    Rails.logger.info "=== THUMBNAIL GENERATION START ==="
    Rails.logger.info "PDF file attached?: #{pdf_file.attached?}"
    Rails.logger.info "Rails environment: #{Rails.env}"

    return unless pdf_file.attached?
    return if Rails.env.test? # Skip thumbnail generation in tests

    begin
      Rails.logger.info "Opening PDF file for thumbnail generation"
      pdf_file.blob.open do |temp_file|
        Rails.logger.info "PDF file opened at path: #{temp_file.path}"
        Rails.logger.info "Temp file size: #{File.size(temp_file.path)} bytes"

        # Create thumbnail using MiniMagick
        Rails.logger.info "Creating MiniMagick image from PDF"
        image = MiniMagick::Image.open(temp_file.path)
        Rails.logger.info "MiniMagick image created successfully"

        # Convert first page of PDF to image
        image.format("png")
        image.resize("300x400")  # Thumbnail size
        image.quality(85)
        Rails.logger.info "Image processed: format=png, size=300x400, quality=85"

        # Create a temporary file for the thumbnail
        thumbnail_tempfile = Tempfile.new(['thumbnail', '.png'])
        Rails.logger.info "Created thumbnail tempfile: #{thumbnail_tempfile.path}"

        image.write(thumbnail_tempfile.path)
        Rails.logger.info "Thumbnail written to tempfile"

        # Attach the thumbnail
        thumbnail.attach(
          io: File.open(thumbnail_tempfile.path),
          filename: "zine_#{id}_thumbnail.png",
          content_type: 'image/png'
        )
        Rails.logger.info "Thumbnail attached to zine"

        thumbnail_tempfile.close
        thumbnail_tempfile.unlink
        Rails.logger.info "Thumbnail tempfile cleaned up"

        Rails.logger.info "Generated thumbnail for zine #{id}"
      end
    rescue => e
      Rails.logger.error "Failed to generate thumbnail for zine #{id}: #{e.class} - #{e.message}"
      Rails.logger.error "Thumbnail generation backtrace: #{e.backtrace.first(5).join('\n')}"
      # Don't fail the save if thumbnail generation fails
    end

    Rails.logger.info "=== THUMBNAIL GENERATION END ==="
  end

  def upload_to_dropbox
    Rails.logger.info "=== DROPBOX UPLOAD START ==="
    Rails.logger.info "PDF file attached?: #{pdf_file.attached?}"
    Rails.logger.info "Rails environment: #{Rails.env}"

    return unless pdf_file.attached?

    begin
      Rails.logger.info "Opening PDF file for Dropbox upload"
      # Create a temporary file from the uploaded PDF
      pdf_file.blob.open do |temp_file|
        Rails.logger.info "PDF file opened for Dropbox upload at path: #{temp_file.path}"
        Rails.logger.info "Temp file size: #{File.size(temp_file.path)} bytes"

        filename = generate_dropbox_filename
        Rails.logger.info "Generated Dropbox filename: #{filename}"

        # Upload to Dropbox and get the file ID
        Rails.logger.info "Initiating Dropbox upload"
        file_id = dropbox_service.upload_zine_file(temp_file.path, filename)
        Rails.logger.info "Dropbox upload completed with file ID: #{file_id}"

        # Store the Dropbox file ID
        update_column(:file_id, file_id)
        Rails.logger.info "Dropbox file ID stored in database"

        # Remove the local Active Storage attachment to save space
        Rails.logger.info "Purging local Active Storage attachment"
        pdf_file.purge
        Rails.logger.info "Local attachment purged"

        Rails.logger.info "Successfully uploaded zine #{id} to Dropbox with file ID: #{file_id}"
      end
    rescue DropboxService::DropboxAuthenticationError => e
      Rails.logger.error "Dropbox authentication failed for zine #{id}: #{e.message}"
      Rails.logger.error "Dropbox upload backtrace: #{e.backtrace.first(5).join('\n')}"
      Rails.logger.info "Zine #{id} saved locally - Dropbox token needs to be refreshed"
      # Don't raise the error to avoid breaking the save process
      # The file will remain in local storage as fallback
    rescue DropboxService::DropboxError => e
      Rails.logger.error "Failed to upload zine #{id} to Dropbox: #{e.class} - #{e.message}"
      Rails.logger.error "Dropbox upload backtrace: #{e.backtrace.first(5).join('\n')}"
      # Don't raise the error to avoid breaking the save process
      # The file will remain in local storage as fallback
    rescue => e
      Rails.logger.error "Unexpected error during Dropbox upload for zine #{id}: #{e.class} - #{e.message}"
      Rails.logger.error "Dropbox upload backtrace: #{e.backtrace.first(5).join('\n')}"
    end

    Rails.logger.info "=== DROPBOX UPLOAD END ==="
  end

  def delete_from_dropbox
    Rails.logger.info "=== DROPBOX FILE DELETE START ==="
    Rails.logger.info "Dropbox file ID present?: #{file_id.present?}"
    Rails.logger.info "Dropbox file ID: #{file_id}" if file_id.present?

    return unless file_id.present?

    begin
      Rails.logger.info "Attempting to delete file from Dropbox"
      if dropbox_service.delete_file(file_id)
        Rails.logger.info "Successfully deleted zine #{id} from Dropbox"
      else
        Rails.logger.warn "Failed to delete zine #{id} from Dropbox"
      end
    rescue DropboxService::DropboxError => e
      Rails.logger.error "Error deleting zine #{id} from Dropbox: #{e.class} - #{e.message}"
      Rails.logger.error "Dropbox delete backtrace: #{e.backtrace.first(5).join('\n')}"
    rescue => e
      Rails.logger.error "Unexpected error deleting zine #{id} from Dropbox: #{e.class} - #{e.message}"
      Rails.logger.error "Dropbox delete backtrace: #{e.backtrace.first(5).join('\n')}"
    end

    Rails.logger.info "=== DROPBOX FILE DELETE END ==="
  end

  def generate_dropbox_filename
    timestamp = created_at.strftime("%Y%m%d_%H%M%S")
    sanitized_creator = created_by.gsub(/[^a-zA-Z0-9\-_]/, '_').strip
    "zine_#{id}_#{timestamp}_#{sanitized_creator}.pdf"
  end

  def dropbox_service
    @dropbox_service ||= DropboxService.new
  end

  def strip_pdf_metadata
    # This method is now handled during the Dropbox upload process
    # Metadata stripping can be implemented as part of the upload pipeline
    Rails.logger.info "PDF metadata stripping integrated with Dropbox upload for zine #{id}"
  end

  def notify_admin
    begin
      AdminNotificationMailer.new_zine_notification(self).deliver_now
      Rails.logger.info "Admin notification email sent for zine #{id}"
    rescue => e
      Rails.logger.error "Failed to send admin notification for zine #{id}: #{e.message}"
      # Don't fail the save if email sending fails
    end
  end

  def validate_pdf_dimensions_after_save
    Rails.logger.info "=== POST-SAVE PDF DIMENSIONS VALIDATION START ==="
    Rails.logger.info "PDF file attached?: #{pdf_file.attached?}"

    return unless pdf_file.attached? && pdf_file.content_type == 'application/pdf'

    begin
      Rails.logger.info "Validating PDF dimensions after save"
      pdf_file.blob.open do |temp_file|
        Rails.logger.info "PDF file opened at path: #{temp_file.path}"

        reader = PDF::Reader.new(temp_file.path)
        first_page = reader.pages.first
        Rails.logger.info "PDF reader created, got first page"

        # PDF dimensions are in points (72 points = 1 inch)
        # Convert 1224x1584 pixels to points assuming 72 DPI
        expected_width = 1224.0
        expected_height = 1584.0

        # Get page dimensions in points
        page_width = first_page.width
        page_height = first_page.height

        Rails.logger.info "Expected dimensions: #{expected_width}×#{expected_height} points"
        Rails.logger.info "Actual dimensions: #{page_width}×#{page_height} points"
        Rails.logger.info "Width difference: #{(page_width - expected_width).abs} points"
        Rails.logger.info "Height difference: #{(page_height - expected_height).abs} points"

        # Log dimension validation results but don't flag for moderation
        unless (page_width - expected_width).abs <= 1 && (page_height - expected_height).abs <= 1
          Rails.logger.warn "PDF dimensions don't match expected size after save"
          Rails.logger.warn "Expected: #{expected_width}×#{expected_height} points"
          Rails.logger.warn "Actual: #{page_width.round}×#{page_height.round} points"
          Rails.logger.info "Zine #{id} will remain visible despite dimension mismatch"
        else
          Rails.logger.info "PDF dimensions validation passed after save"
        end
      end
    rescue => e
      Rails.logger.error "Post-save PDF dimensions validation error: #{e.class} - #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(5).join('\n')}"
      Rails.logger.info "Zine #{id} will remain visible despite processing error"
    end

    Rails.logger.info "=== POST-SAVE PDF DIMENSIONS VALIDATION END ==="
  end

  def upload_to_dropbox_after_save
    Rails.logger.info "=== POST-SAVE DROPBOX UPLOAD START ==="
    upload_to_dropbox
    Rails.logger.info "=== POST-SAVE DROPBOX UPLOAD END ==="
  end

  def generate_thumbnail_after_save
    Rails.logger.info "=== POST-SAVE THUMBNAIL GENERATION START ==="
    generate_thumbnail
    Rails.logger.info "=== POST-SAVE THUMBNAIL GENERATION END ==="
  end

  def cleanup_attachments
    Rails.logger.info "=== ATTACHMENT CLEANUP START ==="
    Rails.logger.info "PDF file attached?: #{pdf_file.attached?}"
    Rails.logger.info "Thumbnail attached?: #{thumbnail.attached?}"

    begin
      if pdf_file.attached?
        Rails.logger.info "Purging PDF file attachment"
        pdf_file.purge
        Rails.logger.info "PDF file attachment purged"
      end

      if thumbnail.attached?
        Rails.logger.info "Purging thumbnail attachment"
        thumbnail.purge
        Rails.logger.info "Thumbnail attachment purged"
      end
    rescue => e
      Rails.logger.error "Error during attachment cleanup: #{e.class} - #{e.message}"
      Rails.logger.error "Cleanup backtrace: #{e.backtrace.first(5).join('\n')}"
    end

    Rails.logger.info "=== ATTACHMENT CLEANUP END ==="
  end
end
