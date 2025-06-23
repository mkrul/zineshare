# Dropbox API Configuration
Rails.application.configure do
  # Dropbox integration settings
  config.dropbox_enabled = !Rails.env.test?

  # Validate Dropbox configuration in production
  if Rails.env.production? && config.dropbox_enabled
    access_token = Rails.application.credentials.dropbox&.access_token || ENV['DROPBOX_ACCESS_TOKEN']

    unless access_token.present?
      Rails.logger.warn "Dropbox API access token not configured. File uploads will fail."
      Rails.logger.warn "Required: dropbox.access_token in Rails credentials"
    end
  end
end

# Log Dropbox configuration status
Rails.application.config.after_initialize do
  if Rails.application.config.dropbox_enabled
    Rails.logger.info "Dropbox integration enabled"
  else
    Rails.logger.info "Dropbox integration disabled (test environment)"
  end
end