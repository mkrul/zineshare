require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  def test_should_be_valid_with_valid_attributes
    assert @user.valid?
  end

  def test_should_require_email
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  def test_should_require_unique_email
    User.create!(email: "test@example.com", password: "password123")
    duplicate_user = User.new(email: "test@example.com", password: "password123")
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "has already been taken"
  end

  def test_should_validate_email_format
    invalid_emails = ["invalid", "@example.com", "test@"]

    invalid_emails.each do |email|
      @user.email = email
      assert_not @user.valid?, "#{email} should be invalid"
      assert_includes @user.errors[:email], "is invalid"
    end
  end

  def test_should_require_password
    @user.password = nil
    @user.password_confirmation = nil
    assert_not @user.valid?
    assert_includes @user.errors[:password], "can't be blank"
  end

  def test_should_require_minimum_password_length
    @user.password = "short"
    @user.password_confirmation = "short"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "is too short (minimum is 8 characters)"
  end

  def test_should_require_password_confirmation
    @user.password_confirmation = "different"
    assert_not @user.valid?
    assert_includes @user.errors[:password_confirmation], "doesn't match Password"
  end

  def test_should_downcase_email
    mixed_case_email = "Test@EXAMPLE.COM"
    @user.email = mixed_case_email
    @user.save!
    assert_equal mixed_case_email.downcase, @user.reload.email
  end

  def test_should_strip_whitespace_from_email
    @user.email = "  test@example.com  "
    @user.save!
    assert_equal "test@example.com", @user.reload.email
  end

  def test_should_encrypt_password
    @user.save!
    assert_not_equal "password123", @user.encrypted_password
    assert @user.encrypted_password.present?
  end
end
