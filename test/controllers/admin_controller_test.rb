require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.create!(email: "admin@example.com", password: "password123", admin: true)
    @user = User.create!(email: "user@example.com", password: "password123", admin: false)
    @category = Category.create!(name: "Test Category")

    @pending_zine = Zine.create!(
      title: "Pending Zine",
      created_by: "Test Creator",
      category: @category,
      user: @user,
      pending_moderation: true
    )

    @approved_zine = Zine.create!(
      title: "Approved Zine",
      created_by: "Test Creator",
      category: @category,
      user: @user,
      pending_moderation: false
    )
  end

  def test_should_require_authentication_for_admin
    get admin_path
    assert_redirected_to new_user_session_path
  end

  def test_should_require_admin_role_for_admin_access
    sign_in @user
    get admin_path
    assert_redirected_to root_path
    assert_match "Access denied", flash[:alert]
  end

  def test_admin_should_access_admin_dashboard
    sign_in @admin
    get admin_path
    assert_response :success
    assert_select "h1", "Admin Dashboard"
  end

    def test_admin_dashboard_should_show_stats
    sign_in @admin
    get admin_path
    assert_response :success

    # Check that pending count includes our test pending zine
    pending_count = Zine.pending_moderation.count
    approved_count = Zine.approved.count
    total_count = Zine.count

    assert_select ".stat-card.pending h3", pending_count.to_s
    assert_select ".stat-card.approved h3", approved_count.to_s
    assert_select ".stat-card.total h3", total_count.to_s
  end

  def test_admin_dashboard_should_list_all_zines
    sign_in @admin
    get admin_path
    assert_response :success

    assert_match @pending_zine.title, response.body
    assert_match @approved_zine.title, response.body
    assert_select ".status-badge.pending", "Pending"
    assert_select ".status-badge.approved", "Approved"
  end

  def test_admin_should_approve_pending_zine
    sign_in @admin

    assert @pending_zine.pending_moderation?

    patch admin_approve_zine_path(@pending_zine)
    assert_redirected_to admin_path
    assert_match "has been approved", flash[:notice]

    @pending_zine.reload
    assert_not @pending_zine.pending_moderation?
  end

  def test_admin_should_reject_pending_zine
    sign_in @admin

    assert_difference("Zine.count", -1) do
      delete admin_reject_zine_path(@pending_zine)
    end

    assert_redirected_to admin_path
    assert_match "has been rejected and deleted", flash[:notice]
  end

  def test_admin_should_delete_any_zine
    sign_in @admin

    assert_difference("Zine.count", -1) do
      delete admin_destroy_zine_path(@approved_zine)
    end

    assert_redirected_to admin_path
    assert_match "has been deleted", flash[:notice]
  end

  def test_non_admin_cannot_approve_zines
    sign_in @user

    patch admin_approve_zine_path(@pending_zine)
    assert_redirected_to root_path
    assert_match "Access denied", flash[:alert]

    @pending_zine.reload
    assert @pending_zine.pending_moderation?
  end

  def test_non_admin_cannot_reject_zines
    sign_in @user

    assert_no_difference("Zine.count") do
      delete admin_reject_zine_path(@pending_zine)
    end

    assert_redirected_to root_path
    assert_match "Access denied", flash[:alert]
  end

  def test_non_admin_cannot_delete_zines_via_admin
    sign_in @user

    assert_no_difference("Zine.count") do
      delete admin_destroy_zine_path(@approved_zine)
    end

    assert_redirected_to root_path
    assert_match "Access denied", flash[:alert]
  end

  def test_admin_nav_link_visible_for_admin
    sign_in @admin
    get root_path
    assert_response :success
    assert_select "a[href='#{admin_path}']", "Admin"
  end

  def test_admin_nav_link_not_visible_for_regular_user
    sign_in @user
    get root_path
    assert_response :success
    assert_select "a[href='#{admin_path}']", count: 0
  end

  def test_all_zines_should_appear_in_public_index
    get zines_path
    assert_response :success

    # All zines should now appear in public listings
    assert_match @approved_zine.title, response.body
    assert_match @pending_zine.title, response.body
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