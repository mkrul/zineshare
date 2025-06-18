# Box.com API Configuration
Rails.application.configure do
  # Box.com integration settings
  config.box_enabled = !Rails.env.test?

  # Validate Box configuration in production
  if Rails.env.production? && config.box_enabled
    unless Rails.application.credentials.box&.access_token || ENV['BOX_ACCESS_TOKEN']
      Rails.logger.warn "Box.com access token not configured. File uploads will fail."
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