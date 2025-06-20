class AdminNotificationMailer < ApplicationMailer
  default from: 'noreply@zineshare.com'

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.admin_notification_mailer.new_zine_notification.subject
  #
  def new_zine_notification(zine)
    @zine = zine
    @zine_url = zine_url(@zine)

    mail(
      to: Rails.application.credentials.admin_email || 'admin@zineshare.com',
      subject: "New Zine Uploaded: #{@zine.title}"
    )
  end
end
