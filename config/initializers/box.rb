# Box.com API Configuration
Rails.application.configure do
  # Box.com integration settings
  config.box_enabled = !Rails.env.test?

  # Validate Box configuration in production
  if Rails.env.production? && config.box_enabled
    client_id = Rails.application.credentials.box&.client_id || ENV['BOX_CLIENT_ID']
    client_secret = Rails.application.credentials.box&.client_secret || ENV['BOX_CLIENT_SECRET']

    unless client_id.present? && client_secret.present?
      Rails.logger.warn "Box.com OAuth2 credentials not configured. File uploads will fail."
      Rails.logger.warn "Required: box.client_id and box.client_secret in Rails credentials"
    end
  end
end

# Log Box configuration status
Rails.application.config.after_initialize do
  if Rails.application.config.box_enabled
    Rails.logger.info "Box.com integration enabled"
  else
    Rails.logger.info "Box.com integration disabled (test environment)"
  end
end