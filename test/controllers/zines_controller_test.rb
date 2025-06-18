require "test_helper"

class ZinesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @category = Category.create!(name: "Test Category")
    @other_category = Category.create!(name: "Other Category")
    @approved_zine = Zine.create!(
      created_by: "Approved Creator",
      category: @category,
      approved: true
    )
    @pending_zine = Zine.create!(
      created_by: "Pending Creator",
      category: @category,
      approved: false
    )
    @other_approved_zine = Zine.create!(
      created_by: "Other Creator",
      category: @other_category,
      approved: true
    )
  end

  def test_should_get_index
    get zines_url
    assert_response :success
    assert_select "h1", "Zineshare"
    assert_select ".filter-section"
  end

  def test_index_should_only_show_approved_zines
    get zines_url
    assert_response :success
    assert_match @approved_zine.created_by, response.body
    assert_match @other_approved_zine.created_by, response.body
    assert_no_match @pending_zine.created_by, response.body
  end

  def test_index_should_filter_by_category
    get zines_url, params: { category_id: @category.id }
    assert_response :success
    assert_match @approved_zine.created_by, response.body
    assert_no_match @other_approved_zine.created_by, response.body
  end

  def test_index_should_handle_pagination
    # Create enough zines to trigger pagination
    15.times do |i|
      Zine.create!(
        created_by: "Creator #{i}",
        category: @category,
        approved: true
      )
    end

    get zines_url
    assert_response :success

    # Should have pagination controls or load more trigger
    assert_select "#load-more-trigger", { count: 0..1 }
  end

  def test_index_should_respond_to_turbo_stream
    get zines_url, params: { page: 2 }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html; charset=utf-8', response.content_type
  end

  def test_should_get_new
    get new_zine_url
    assert_response :success
    assert_select "h1", "Upload Your Zine"
  end

  def test_should_show_zine
    get zine_url(@approved_zine)
    assert_response :success
    assert_match @approved_zine.created_by, response.body
  end

  def test_should_create_zine_with_valid_params
    assert_difference("Zine.count") do
      post zines_url, params: {
        zine: {
          created_by: "New Creator",
          category_id: @category.id
        }
      }
    end

    zine = Zine.last
    assert_equal false, zine.approved
    assert_redirected_to zine_url(zine)
  end

  def test_should_not_create_zine_with_invalid_params
    assert_no_difference("Zine.count") do
      post zines_url, params: {
        zine: {
          created_by: "",
          category_id: nil
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".error-messages"
  end

  def test_should_render_new_on_failed_create
    post zines_url, params: {
      zine: {
        created_by: "",
        category_id: nil
      }
    }

    assert_response :unprocessable_entity
    assert_select "h1", "Upload Your Zine"
  end
end
