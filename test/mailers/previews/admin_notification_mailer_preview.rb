# Preview all emails at http://localhost:3000/rails/mailers/admin_notification_mailer
class AdminNotificationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/admin_notification_mailer/new_zine_notification
  def new_zine_notification
    AdminNotificationMailer.new_zine_notification
  end
end
