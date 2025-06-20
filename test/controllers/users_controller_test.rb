require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "test@example.com", password: "password123")
    @category = Category.create!(name: "Test Category")
    @user_zine = Zine.create!(
      title: "User Zine",
      created_by: "User Creator",
      category: @category,
      user: @user
    )
  end

  def test_should_require_authentication_for_dashboard
    get dashboard_path
    assert_redirected_to new_user_session_path
  end

  def test_should_get_dashboard_when_authenticated
    sign_in @user
    get dashboard_path
    assert_response :success
    assert_select "h1", "My Dashboard"
    assert_match @user_zine.created_by, response.body
  end

  def test_dashboard_should_show_user_zines_only
    other_user = User.create!(email: "other@example.com", password: "password123")
    other_zine = Zine.create!(
      title: "Other Zine",
      created_by: "Other Creator",
      category: @category,
      user: other_user
    )

    sign_in @user
    get dashboard_path
    assert_response :success
    assert_match @user_zine.created_by, response.body
    assert_no_match other_zine.created_by, response.body
  end

  def test_dashboard_should_show_zine_count
    sign_in @user
    get dashboard_path
    assert_response :success
    assert_select ".stat-card h3", "1"
  end

  def test_dashboard_should_show_action_buttons
    sign_in @user
    get dashboard_path
    assert_response :success
    assert_select "a[href='#{edit_zine_path(@user_zine)}']", "Edit"
    assert_select "a[href='#{zine_path(@user_zine)}'][data-method='delete']", "Delete"
  end

  def test_dashboard_should_include_view_toggle_buttons
    sign_in @user
    get dashboard_path
    assert_response :success
    assert_select ".view-btn[data-view='grid']", "Grid View"
    assert_select ".view-btn[data-view='list']", "List View"
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