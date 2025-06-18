class BoxService
  class BoxError < StandardError; end
  class BoxUploadError < BoxError; end
  class BoxAuthenticationError < BoxError; end

  ZINES_FOLDER_NAME = 'Zineshare Uploads'

  def initialize
    @client = create_client
  end

  def upload_zine_file(file_path, filename)
    ensure_zines_folder_exists

    begin
      uploaded_file = @client.upload_file(file_path, @zines_folder_id, name: filename)
      uploaded_file.id
    rescue => e
      Rails.logger.error "Box upload failed: #{e.message}"
      raise BoxUploadError, "Failed to upload file to Box: #{e.message}"
    end
  end

  def get_file_download_url(file_id)
    begin
      @client.download_url(file_id)
    rescue => e
      Rails.logger.error "Box download URL failed: #{e.message}"
      raise BoxError, "Failed to get download URL: #{e.message}"
    end
  end

  def delete_file(file_id)
    begin
      @client.delete_file(file_id)
      true
    rescue => e
      Rails.logger.error "Box file deletion failed: #{e.message}"
      false
    end
  end

  def file_exists?(file_id)
    begin
      @client.file(file_id)
      true
    rescue
      false
    end
  end

  private

  def create_client
    begin
      Boxr::Client.new(access_token)
    rescue => e
      Rails.logger.error "Box client creation failed: #{e.message}"
      raise BoxAuthenticationError, "Failed to authenticate with Box: #{e.message}"
    end
  end

  def access_token
    # In production, this should use JWT authentication or OAuth
    # For now, we'll use a simple access token from credentials
    Rails.application.credentials.box&.access_token ||
      ENV['BOX_ACCESS_TOKEN'] ||
      raise(BoxAuthenticationError, "Box access token not configured")
  end

  def ensure_zines_folder_exists
    return if @zines_folder_id

    begin
      # Try to find existing folder
      root_items = @client.folder_items(0, fields: [:name, :id])
      existing_folder = root_items.find { |item| item.name == ZINES_FOLDER_NAME && item.type == 'folder' }

      if existing_folder
        @zines_folder_id = existing_folder.id
      else
        # Create new folder
        new_folder = @client.create_folder(ZINES_FOLDER_NAME, 0)
        @zines_folder_id = new_folder.id
      end

      Rails.logger.info "Using Box folder '#{ZINES_FOLDER_NAME}' with ID: #{@zines_folder_id}"
    rescue => e
      Rails.logger.error "Box folder creation/lookup failed: #{e.message}"
      raise BoxError, "Failed to setup Box folder: #{e.message}"
    end
  end
end