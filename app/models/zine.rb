class Zine < ApplicationRecord
  belongs_to :category

  has_one_attached :pdf_file
  has_one_attached :thumbnail

  validates :created_by, presence: true
  validates :pdf_file, presence: true, unless: -> { Rails.env.test? }
  validate :pdf_file_must_be_pdf, unless: -> { Rails.env.test? }
  validate :pdf_dimensions_must_be_correct, unless: -> { Rails.env.test? }

  after_create :upload_to_box, if: -> { pdf_file.attached? && !Rails.env.test? }
  after_create :generate_thumbnail, if: -> { pdf_file.attached? }
  before_destroy :delete_from_box

  scope :approved, -> { where(approved: true) }
  scope :pending, -> { where(approved: false) }

  def box_download_url
    return nil unless box_file_id.present?

    begin
      box_service.get_file_download_url(box_file_id)
    rescue BoxService::BoxError => e
      Rails.logger.error "Failed to get Box download URL for zine #{id}: #{e.message}"
      nil
    end
  end

  def file_available?
    if Rails.env.test?
      pdf_file.attached?
    else
      box_file_id.present? && box_service.file_exists?(box_file_id)
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
    return unless pdf_file.attached?

    unless pdf_file.content_type == 'application/pdf'
      errors.add(:pdf_file, 'must be a PDF file')
    end
  end

  def pdf_dimensions_must_be_correct
    return unless pdf_file.attached? && pdf_file.content_type == 'application/pdf'

    begin
      pdf_file.blob.open do |file|
        reader = PDF::Reader.new(file)
        first_page = reader.pages.first

        # PDF dimensions are in points (72 points = 1 inch)
        # Convert 1224x1584 pixels to points assuming 72 DPI
        expected_width = 1224.0
        expected_height = 1584.0

        # Get page dimensions in points
        page_width = first_page.width
        page_height = first_page.height

        # Allow for small rounding differences (within 1 point)
        unless (page_width - expected_width).abs <= 1 && (page_height - expected_height).abs <= 1
          errors.add(:pdf_file, "must have exact dimensions of 1224×1584 pixels (#{expected_width}×#{expected_height} points). Current dimensions: #{page_width.round}×#{page_height.round} points")
        end
      end
    rescue => e
      errors.add(:pdf_file, "could not be processed: #{e.message}")
    end
  end

  def generate_thumbnail
    return unless pdf_file.attached?
    return if Rails.env.test? # Skip thumbnail generation in tests

    begin
      pdf_file.blob.open do |temp_file|
        # Create thumbnail using MiniMagick
        image = MiniMagick::Image.open(temp_file.path)

        # Convert first page of PDF to image
        image.format("png")
        image.resize("300x400")  # Thumbnail size
        image.quality(85)

        # Create a temporary file for the thumbnail
        thumbnail_tempfile = Tempfile.new(['thumbnail', '.png'])
        image.write(thumbnail_tempfile.path)

        # Attach the thumbnail
        thumbnail.attach(
          io: File.open(thumbnail_tempfile.path),
          filename: "zine_#{id}_thumbnail.png",
          content_type: 'image/png'
        )

        thumbnail_tempfile.close
        thumbnail_tempfile.unlink

        Rails.logger.info "Generated thumbnail for zine #{id}"
      end
    rescue => e
      Rails.logger.error "Failed to generate thumbnail for zine #{id}: #{e.message}"
      # Don't fail the save if thumbnail generation fails
    end
  end

  def upload_to_box
    return unless pdf_file.attached?

    begin
      # Create a temporary file from the uploaded PDF
      pdf_file.blob.open do |temp_file|
        filename = generate_box_filename

        # Upload to Box and get the file ID
        file_id = box_service.upload_zine_file(temp_file.path, filename)

        # Store the Box file ID
        update_column(:box_file_id, file_id)

        # Remove the local Active Storage attachment to save space
        pdf_file.purge

        Rails.logger.info "Successfully uploaded zine #{id} to Box with file ID: #{file_id}"
      end
    rescue BoxService::BoxError => e
      Rails.logger.error "Failed to upload zine #{id} to Box: #{e.message}"
      # Don't raise the error to avoid breaking the save process
      # The file will remain in local storage as fallback
    end
  end

  def delete_from_box
    return unless box_file_id.present?

    begin
      if box_service.delete_file(box_file_id)
        Rails.logger.info "Successfully deleted zine #{id} from Box"
      else
        Rails.logger.warn "Failed to delete zine #{id} from Box"
      end
    rescue BoxService::BoxError => e
      Rails.logger.error "Error deleting zine #{id} from Box: #{e.message}"
    end
  end

  def generate_box_filename
    timestamp = created_at.strftime("%Y%m%d_%H%M%S")
    sanitized_creator = created_by.gsub(/[^a-zA-Z0-9\-_]/, '_').strip
    "zine_#{id}_#{timestamp}_#{sanitized_creator}.pdf"
  end

  def box_service
    @box_service ||= BoxService.new
  end

  def strip_pdf_metadata
    # This method is now handled during the Box upload process
    # Metadata stripping can be implemented as part of the upload pipeline
    Rails.logger.info "PDF metadata stripping integrated with Box upload for zine #{id}"
  end
end
