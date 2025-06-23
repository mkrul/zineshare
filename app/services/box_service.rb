class BoxService
  class BoxError < StandardError; end
  class BoxUploadError < BoxError; end
  class BoxAuthenticationError < BoxError; end

  ZINES_FOLDER_NAME = 'Zineshare Uploads'

  def initialize
    Rails.logger.info "=== BOX SERVICE INITIALIZATION START ==="
    @client = create_client
    Rails.logger.info "Box client created successfully"
    Rails.logger.info "=== BOX SERVICE INITIALIZATION END ==="
  end

  def upload_zine_file(file_path, filename)
    Rails.logger.info "=== BOX SERVICE UPLOAD START ==="
    Rails.logger.info "File path: #{file_path}"
    Rails.logger.info "Filename: #{filename}"
    Rails.logger.info "File exists?: #{File.exist?(file_path)}"
    Rails.logger.info "File size: #{File.size(file_path)} bytes" if File.exist?(file_path)

    ensure_zines_folder_exists

    begin
      Rails.logger.info "Initiating Box API upload"
      uploaded_file = @client.upload_file(file_path, @zines_folder_id, name: filename)
      Rails.logger.info "Box API upload successful"
      Rails.logger.info "Uploaded file ID: #{uploaded_file.id}"
      Rails.logger.info "Uploaded file name: #{uploaded_file.name}"

      uploaded_file.id
    rescue => e
      Rails.logger.error "Box upload failed: #{e.class} - #{e.message}"
      Rails.logger.error "Box upload backtrace: #{e.backtrace.first(10).join('\n')}"
      raise BoxUploadError, "Failed to upload file to Box: #{e.message}"
    ensure
      Rails.logger.info "=== BOX SERVICE UPLOAD END ==="
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
    Rails.logger.info "Creating Box client with OAuth2 Client Credentials"
    begin
      access_token = obtain_access_token
      client = Boxr::Client.new(access_token)
      Rails.logger.info "Box client created successfully with OAuth2"
      client
    rescue => e
      Rails.logger.error "Box client creation failed: #{e.class} - #{e.message}"
      Rails.logger.error "Box client creation backtrace: #{e.backtrace.first(5).join('\n')}"
      raise BoxAuthenticationError, "Failed to authenticate with Box: #{e.message}"
    end
  end

  def obtain_access_token
    Rails.logger.info "Obtaining Box access token via Client Credentials Grant"

    client_id = Rails.application.credentials.box&.client_id || ENV['BOX_CLIENT_ID']
    client_secret = Rails.application.credentials.box&.client_secret || ENV['BOX_CLIENT_SECRET']
    enterprise_id = Rails.application.credentials.box&.enterprise_id || ENV['BOX_ENTERPRISE_ID']

    unless client_id.present? && client_secret.present?
      Rails.logger.error "Box client credentials not configured"
      raise BoxAuthenticationError, "Box client_id and client_secret must be configured"
    end

    begin
      require 'net/http'
      require 'uri'
      require 'json'

      # Make direct HTTP request to Box OAuth2 token endpoint
      uri = URI('https://api.box.com/oauth2/token')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/x-www-form-urlencoded'

      # Build request body for Client Credentials Grant
      params = {
        'grant_type' => 'client_credentials',
        'client_id' => client_id,
        'client_secret' => client_secret
      }

      # For App Access Only authentication, we don't need subject parameters
      Rails.logger.info "Authenticating with App Access Only"
      Rails.logger.info "Client ID: #{client_id}"
      Rails.logger.info "App will authenticate as its Service Account"

      request.body = URI.encode_www_form(params)
      Rails.logger.info "Making OAuth2 token request to Box API"
      Rails.logger.debug "Request params: #{params.except('client_secret')}" # Log without secret
      Rails.logger.debug "Request body: #{request.body.gsub(client_secret, '[REDACTED]')}" # Log actual body

      response = http.request(request)

      if response.code == '200'
        token_data = JSON.parse(response.body)
        Rails.logger.info "Successfully obtained Box access token via OAuth2"
        Rails.logger.info "Token expires in: #{token_data['expires_in']} seconds" if token_data['expires_in']
        token_data['access_token']
      else
        Rails.logger.error "Box OAuth2 token request failed: #{response.code} #{response.message}"
        Rails.logger.error "Response body: #{response.body}"

        # Parse error response for more details
        begin
          error_data = JSON.parse(response.body)
          Rails.logger.error "Box error: #{error_data['error']}"
          Rails.logger.error "Box error description: #{error_data['error_description']}"
        rescue
          # If response isn't JSON, that's fine
        end

        raise BoxAuthenticationError, "Failed to obtain Box access token: #{response.code} #{response.message}"
      end
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse Box OAuth2 response: #{e.message}"
      raise BoxAuthenticationError, "Invalid response from Box OAuth2 endpoint"
    rescue => e
      Rails.logger.error "Failed to obtain Box access token: #{e.class} - #{e.message}"
      Rails.logger.error "OAuth2 authentication backtrace: #{e.backtrace.first(5).join('\n')}"
      raise BoxAuthenticationError, "Failed to obtain Box access token via OAuth2: #{e.message}"
    end
  end

  def ensure_zines_folder_exists
    Rails.logger.info "Ensuring zines folder exists"
    return if @zines_folder_id.present?

    Rails.logger.info "Searching for existing zines folder"
    begin
      folders = @client.folder_items(0, fields: [:name])
      Rails.logger.info "Found #{folders.count} items in root folder"

      zines_folder = folders.find { |item| item.name == ZINES_FOLDER_NAME && item.type == 'folder' }

      if zines_folder
        Rails.logger.info "Found existing zines folder with ID: #{zines_folder.id}"
        @zines_folder_id = zines_folder.id
      else
        Rails.logger.info "Creating new zines folder"
        created_folder = @client.create_folder(ZINES_FOLDER_NAME, 0)
        @zines_folder_id = created_folder.id
        Rails.logger.info "Created zines folder with ID: #{@zines_folder_id}"
      end
    rescue Boxr::BoxrError => e
      if e.message.include?("invalid_token")
        Rails.logger.error "Box authentication failed - token expired or invalid"
        raise BoxAuthenticationError, "Box access token expired or invalid. Please refresh the token."
      else
        Rails.logger.error "Failed to ensure zines folder exists: #{e.class} - #{e.message}"
        Rails.logger.error "Zines folder creation backtrace: #{e.backtrace.first(5).join('\n')}"
        raise BoxError, "Failed to create or find zines folder: #{e.message}"
      end
    rescue => e
      Rails.logger.error "Failed to ensure zines folder exists: #{e.class} - #{e.message}"
      Rails.logger.error "Zines folder creation backtrace: #{e.backtrace.first(5).join('\n')}"
      raise BoxError, "Failed to create or find zines folder: #{e.message}"
    end
  end
end