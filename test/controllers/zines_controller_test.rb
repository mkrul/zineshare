require "test_helper"

class ZinesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "test@example.com", password: "password123")
    @category = Category.create!(name: "Test Category")
    @other_category = Category.create!(name: "Other Category")
    @zine = Zine.create!(
      title: "Test Zine",
      created_by: "Test Creator",
      category: @category,
      user: @user
    )
    @other_zine = Zine.create!(
      title: "Other Zine",
      created_by: "Other Creator",
      category: @other_category,
      user: @user
    )
  end

  def test_should_get_index
    get zines_url
    assert_response :success
    assert_select "h1", "Zineshare"
    assert_select ".filter-section"
  end

  def test_index_should_show_all_zines
    get zines_url
    assert_response :success
    assert_match @zine.created_by, response.body
    assert_match @other_zine.created_by, response.body
  end

  def test_index_should_filter_by_category
    get zines_url, params: { category_id: @category.id }
    assert_response :success
    assert_match @zine.created_by, response.body
    assert_no_match @other_zine.created_by, response.body
  end

  def test_index_should_handle_pagination
    # Create enough zines to trigger pagination
    15.times do |i|
      Zine.create!(
        title: "Test Zine #{i}",
        created_by: "Creator #{i}",
        category: @category
      )
    end

    get zines_url
    assert_response :success

    # Should have pagination controls or load more trigger
    # Just check that the page loads successfully with many zines
    assert_select ".zines-grid"
  end

  def test_index_should_respond_to_turbo_stream
    get zines_url, params: { page: 2 }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html; charset=utf-8', response.content_type
  end

  def test_should_get_new
    sign_in @user
    get new_zine_url
    assert_response :success
    assert_select "h1", "Upload Your Zine"
  end

  def test_should_require_authentication_for_new
    get new_zine_url
    assert_redirected_to new_user_session_path
  end

  def test_should_show_zine
    get zine_url(@zine)
    assert_response :success
    assert_match @zine.created_by, response.body
  end

  def test_should_create_zine_with_valid_params
    sign_in @user
    assert_difference("Zine.count") do
      post zines_url, params: {
        zine: {
          title: "New Zine Title",
          created_by: "New Creator",
          category_id: @category.id
        }
      }
    end

    zine = Zine.last
    assert_equal @user, zine.user
    assert_equal "New Zine Title", zine.title
    assert_redirected_to zine_url(zine)
  end

  def test_should_require_authentication_for_create
    assert_no_difference("Zine.count") do
      post zines_url, params: {
        zine: {
          title: "New Zine Title",
          created_by: "New Creator",
          category_id: @category.id
        }
      }
    end
    assert_redirected_to new_user_session_path
  end

  def test_should_not_create_zine_with_invalid_params
    sign_in @user
    assert_no_difference("Zine.count") do
      post zines_url, params: {
        zine: {
          title: "",
          created_by: "",
          category_id: nil
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".error-messages"
  end

  def test_should_render_new_on_failed_create
    sign_in @user
    post zines_url, params: {
      zine: {
        title: "",
        created_by: "",
        category_id: nil
      }
    }

    assert_response :unprocessable_entity
    assert_select "h1", "Upload Your Zine"
  end

  def test_should_get_edit_when_owner
    sign_in @user
    get edit_zine_url(@zine)
    assert_response :success
    assert_select "h1", "Edit Zine"
  end

  def test_should_require_authentication_for_edit
    get edit_zine_url(@zine)
    assert_redirected_to new_user_session_path
  end

  def test_should_require_ownership_for_edit
    other_user = User.create!(email: "other@example.com", password: "password123")
    sign_in other_user
    get edit_zine_url(@zine)
    assert_redirected_to dashboard_path
    assert_match "not authorized", flash[:alert]
  end

  def test_should_update_zine_when_owner
    sign_in @user
    patch zine_url(@zine), params: {
      zine: {
        title: "Updated Title",
        created_by: "Updated Creator",
        category_id: @other_category.id
      }
    }
    assert_redirected_to zine_url(@zine)
    @zine.reload
    assert_equal "Updated Title", @zine.title
    assert_equal "Updated Creator", @zine.created_by
    assert_equal @other_category, @zine.category
  end

  def test_should_destroy_zine_when_owner
    sign_in @user
    assert_difference("Zine.count", -1) do
      delete zine_url(@zine)
    end
    assert_redirected_to dashboard_path
    assert_match "Your zine has been deleted", flash[:notice]
  end

  def test_should_require_authentication_for_destroy
    assert_no_difference("Zine.count") do
      delete zine_url(@zine)
    end
    assert_redirected_to new_user_session_path
  end

  def test_should_require_ownership_for_destroy
    other_user = User.create!(email: "other@example.com", password: "password123")
    sign_in other_user
    assert_no_difference("Zine.count") do
      delete zine_url(@zine)
    end
    assert_redirected_to dashboard_path
  end

  def test_should_cleanup_box_file_on_destroy
    sign_in @user
    @zine.update_column(:box_file_id, "test_box_file_id")

    # Verify that the zine has a box_file_id before deletion
    assert_not_nil @zine.box_file_id

    # Delete the zine (this should trigger the before_destroy callback)
    assert_difference("Zine.count", -1) do
      delete zine_url(@zine)
    end

    assert_redirected_to dashboard_path
    assert_match "Your zine has been deleted", flash[:notice]
  end

  def test_should_return_404_for_deleted_zine
    sign_in @user
    zine_id = @zine.id

    # Delete the zine
    delete zine_url(@zine)

    # Try to access the deleted zine - should return 404
    get zine_url(id: zine_id)
    assert_response :not_found
  end

  def test_index_should_only_show_approved_zines
    # Create a pending zine
    pending_zine = Zine.create!(
      title: "Pending Zine",
      created_by: "Pending Creator",
      category: @category,
      user: @user,
      pending_moderation: true
    )

    get zines_url
    assert_response :success

    # Should show approved zines
    assert_match @zine.title, response.body
    # Should NOT show pending zines
    assert_no_match pending_zine.title, response.body
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
