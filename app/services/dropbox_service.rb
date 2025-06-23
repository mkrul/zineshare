class DropboxService
  class DropboxError < StandardError; end
  class DropboxUploadError < DropboxError; end
  class DropboxAuthenticationError < DropboxError; end

  ZINES_FOLDER_PATH = '/Zineshare Uploads'

  def initialize
    Rails.logger.info "=== DROPBOX SERVICE INITIALIZATION START ==="
    @client = create_client
    Rails.logger.info "Dropbox client created successfully"
    Rails.logger.info "=== DROPBOX SERVICE INITIALIZATION END ==="
  end

  def upload_zine_file(file_path, filename)
    Rails.logger.info "=== DROPBOX SERVICE UPLOAD START ==="
    Rails.logger.info "File path: #{file_path}"
    Rails.logger.info "Filename: #{filename}"
    Rails.logger.info "File exists?: #{File.exist?(file_path)}"
    Rails.logger.info "File size: #{File.size(file_path)} bytes" if File.exist?(file_path)

    ensure_zines_folder_exists

    begin
      file_content = File.read(file_path, mode: 'rb')
      dropbox_path = "#{ZINES_FOLDER_PATH}/#{filename}"

      Rails.logger.info "Initiating Dropbox API upload to path: #{dropbox_path}"
      result = @client.upload(dropbox_path, file_content, mode: :overwrite)

      Rails.logger.info "Dropbox API upload successful"
      Rails.logger.info "Uploaded file ID: #{result.id}"
      Rails.logger.info "Uploaded file path: #{result.path_display}"

      result.id
    rescue => e
      Rails.logger.error "Dropbox upload failed: #{e.class} - #{e.message}"
      Rails.logger.error "Dropbox upload backtrace: #{e.backtrace.first(10).join('\n')}"
      raise DropboxUploadError, "Failed to upload file to Dropbox: #{e.message}"
    ensure
      Rails.logger.info "=== DROPBOX SERVICE UPLOAD END ==="
    end
  end

  def get_file_download_url(file_id)
    begin
      metadata = @client.get_metadata(file_id)
      result = @client.get_temporary_link(metadata.path_display)
      result.link
    rescue => e
      Rails.logger.error "Dropbox download URL failed: #{e.message}"
      raise DropboxError, "Failed to get download URL: #{e.message}"
    end
  end

  def delete_file(file_id)
    begin
      metadata = @client.get_metadata(file_id)
      @client.delete(metadata.path_display)
      true
    rescue => e
      Rails.logger.error "Dropbox file deletion failed: #{e.message}"
      false
    end
  end

  def file_exists?(file_id)
    begin
      @client.get_metadata(file_id)
      true
    rescue
      false
    end
  end

  private

  def create_client
    Rails.logger.info "Creating Dropbox client"
    begin
      # Try multiple ways to access the credentials
      dropbox_creds = Rails.application.credentials.dropbox
      Rails.logger.info "Dropbox credentials object: #{dropbox_creds.class.name}"
      Rails.logger.info "Dropbox credentials present?: #{dropbox_creds.present?}"

      access_token = nil

      if dropbox_creds
        # Try symbol access
        access_token = dropbox_creds[:access_token]
        Rails.logger.info "Access token via symbol: #{access_token.present? ? 'Found' : 'Not found'}"

        # Try string access if symbol didn't work
        if access_token.blank? && dropbox_creds.respond_to?(:[])
          access_token = dropbox_creds['access_token']
          Rails.logger.info "Access token via string: #{access_token.present? ? 'Found' : 'Not found'}"
        end

        # Try method access if hash access didn't work
        if access_token.blank? && dropbox_creds.respond_to?(:access_token)
          access_token = dropbox_creds.access_token
          Rails.logger.info "Access token via method: #{access_token.present? ? 'Found' : 'Not found'}"
        end
      end

      # Fall back to environment variable
      if access_token.blank?
        access_token = ENV['DROPBOX_ACCESS_TOKEN']
        Rails.logger.info "Access token via ENV: #{access_token.present? ? 'Found' : 'Not found'}"
      end

      unless access_token.present?
        Rails.logger.error "Dropbox access token not configured"
        Rails.logger.error "Credentials keys: #{dropbox_creds&.keys}" if dropbox_creds.respond_to?(:keys)
        raise DropboxAuthenticationError, "Dropbox access_token must be configured"
      end

      Rails.logger.info "Access token found, length: #{access_token.length}"
      require 'dropbox_api'
      client = DropboxApi::Client.new(access_token)

      Rails.logger.info "Dropbox client created successfully"
      client
    rescue => e
      Rails.logger.error "Dropbox client creation failed: #{e.class} - #{e.message}"
      Rails.logger.error "Dropbox client creation backtrace: #{e.backtrace.first(5).join('\n')}"
      raise DropboxAuthenticationError, "Failed to authenticate with Dropbox: #{e.message}"
    end
  end

  def ensure_zines_folder_exists
    Rails.logger.info "Ensuring zines folder exists"

    begin
      @client.list_folder('')
      folders = @client.list_folder('').entries.select { |e| e.is_a?(DropboxApi::Metadata::Folder) }

      zines_folder_exists = folders.any? { |folder| folder.path_display == ZINES_FOLDER_PATH }

      unless zines_folder_exists
        Rails.logger.info "Creating new zines folder"
        @client.create_folder(ZINES_FOLDER_PATH)
        Rails.logger.info "Created zines folder at #{ZINES_FOLDER_PATH}"
      else
        Rails.logger.info "Zines folder already exists"
      end
    rescue DropboxApi::Errors::ExpiredAccessTokenError => e
      error_msg = "Dropbox app permissions issue: #{e.message}"
      Rails.logger.error error_msg
      Rails.logger.error "This usually means your Dropbox app needs additional scopes:"
      Rails.logger.error "Required scopes: files.metadata.write, files.metadata.read, files.content.write, files.content.read"
      Rails.logger.error "After adding scopes, generate a new access token"
      raise DropboxError, "#{error_msg}. Please check app permissions and regenerate access token."
    rescue => e
      Rails.logger.error "Failed to ensure zines folder exists: #{e.class} - #{e.message}"
      Rails.logger.error "Zines folder creation backtrace: #{e.backtrace.first(5).join('\n')}"
      raise DropboxError, "Failed to create or find zines folder: #{e.message}"
    end
  end
end