require "test_helper"

class UserAuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123"
    )
  end

  def test_user_can_sign_up
    get new_user_registration_path
    assert_response :success
    assert_select "h1", "Create Your Account"

    assert_difference("User.count") do
      post user_registration_path, params: {
        user: {
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    # Should redirect and auto-login after successful registration
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_select ".nav-user-email", "newuser@example.com"
  end

  def test_user_cannot_sign_up_with_invalid_data
    get new_user_registration_path
    assert_response :success

    assert_no_difference("User.count") do
      post user_registration_path, params: {
        user: {
          email: "invalid-email",
          password: "short",
          password_confirmation: "different"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".error-messages"
  end

  def test_user_can_sign_in
    get new_user_session_path
    assert_response :success
    assert_select "h1", "Sign In"

    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "password123"
      }
    }

    assert_redirected_to dashboard_path
    follow_redirect!
    assert_select ".nav-user-email", @user.email
  end

  def test_user_cannot_sign_in_with_invalid_credentials
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "wrongpassword"
      }
    }

    assert_response :unprocessable_entity
    assert_select ".alert", /Invalid Email or password/
  end

  def test_user_can_sign_out
    sign_in @user

    delete destroy_user_session_path
    assert_redirected_to root_path

    follow_redirect!
    assert_select ".nav-auth" # Should show sign in/sign up links
    assert_no_match @user.email, response.body
  end

  def test_signed_in_user_sees_account_navigation
    sign_in @user

    get root_path
    assert_response :success
    assert_select ".nav-user-email", @user.email
    assert_select "a[href='#{dashboard_path}']", "Dashboard"
    assert_select "a[href='#{edit_user_registration_path}']", "Account"
    assert_select "a[href='#{destroy_user_session_path}']", "Sign Out"
  end

  def test_signed_out_user_sees_auth_navigation
    get root_path
    assert_response :success
    assert_select ".nav-auth"
    assert_select "a[href='#{new_user_session_path}']", "Sign In"
    assert_select "a[href='#{new_user_registration_path}']", "Sign Up"
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end
end