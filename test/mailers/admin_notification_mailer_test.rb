require "test_helper"

class AdminNotificationMailerTest < ActionMailer::TestCase
  def setup
    @category = Category.create!(name: "Test Category")
    @user = User.create!(email: "test@example.com", password: "password123")
    @zine = Zine.create!(
      title: "Test Zine",
      created_by: "Test Creator",
      category: @category,
      user: @user
    )
  end

  def test_new_zine_notification
    email = AdminNotificationMailer.new_zine_notification(@zine)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ["admin@zineshare.com"], email.to
    assert_equal "New Zine Uploaded: Test Zine", email.subject

    # Check both text and HTML parts
    assert_includes email.text_part.body.to_s, "Test Zine"
    assert_includes email.text_part.body.to_s, "Test Creator"
    assert_includes email.text_part.body.to_s, "Test Category"

    assert_includes email.html_part.body.to_s, "Test Zine"
    assert_includes email.html_part.body.to_s, "Test Creator"
    assert_includes email.html_part.body.to_s, "Test Category"
  end
end
