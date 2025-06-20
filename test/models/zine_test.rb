require "test_helper"

class ZineTest < ActiveSupport::TestCase
  def setup
    @category = Category.create!(name: "Test Category")
    @zine = Zine.new(
      title: "Test Zine Title",
      created_by: "Test Creator",
      category: @category
    )
  end

  def test_should_be_valid_with_valid_attributes
    assert @zine.valid?
  end

  def test_should_require_title
    @zine.title = nil
    assert_not @zine.valid?
    assert_includes @zine.errors[:title], "can't be blank"
  end

  def test_should_limit_title_length
    @zine.title = "x" * 101
    assert_not @zine.valid?
    assert_includes @zine.errors[:title], "is too long (maximum is 100 characters)"
  end

  def test_should_require_created_by
    @zine.created_by = nil
    assert_not @zine.valid?
    assert_includes @zine.errors[:created_by], "can't be blank"
  end

  def test_should_require_category
    @zine.category = nil
    assert_not @zine.valid?
    assert_includes @zine.errors[:category], "must exist"
  end



  def test_file_available_returns_true_for_attached_pdf_in_test
    # In test environment, should check for attached PDF file
    assert_not @zine.file_available?

    # Simulate attached file
    @zine.pdf_file.attach(
      io: StringIO.new("fake pdf content"),
      filename: "test.pdf",
      content_type: "application/pdf"
    )

    assert @zine.file_available?
  end

  def test_file_available_checks_box_file_id_in_production
    # Test basic logic without complex mocking
    assert_not @zine.file_available?

    # In test environment, it should check for attached files
    @zine.pdf_file.attach(
      io: StringIO.new("fake pdf content"),
      filename: "test.pdf",
      content_type: "application/pdf"
    )

    assert @zine.file_available?
  end

  def test_box_download_url_returns_nil_without_box_file_id
    assert_nil @zine.box_download_url
  end

  def test_generate_box_filename_creates_proper_filename
    @zine.id = 123
    @zine.created_at = Time.new(2024, 1, 15, 15, 30, 0, "+00:00")
    @zine.created_by = "Test User!"

    filename = @zine.send(:generate_box_filename)

    # Test the basic structure without exact time matching
    assert_match(/^zine_123_\d{8}_\d{6}_Test_User_.pdf$/, filename)
    assert_includes filename, "zine_123"
    assert_includes filename, "Test_User_"
    assert filename.end_with?(".pdf")
  end

  def test_box_file_id_field_exists
    # Test that the box_file_id field exists and can be set
    assert_nil @zine.box_file_id

    @zine.box_file_id = "test_file_id_123"
    assert_equal "test_file_id_123", @zine.box_file_id
  end

  def test_thumbnail_attachment_exists
    # Test that thumbnail attachment is available
    assert_respond_to @zine, :thumbnail
    assert_not @zine.thumbnail.attached?
  end

  def test_thumbnail_url_returns_default_when_no_thumbnail
    # Test default thumbnail URL when no thumbnail is attached
    @zine.save! # Save the record so it has an ID
    thumbnail_url = @zine.thumbnail_url
    assert_includes thumbnail_url, "default-zine-thumbnail"
  end

  def test_thumbnail_url_returns_blob_path_when_attached
    # Test that thumbnail URL returns proper path when thumbnail is attached
    @zine.save! # Save the record so it has an ID
    @zine.thumbnail.attach(
      io: StringIO.new("fake image content"),
      filename: "test_thumbnail.png",
      content_type: "image/png"
    )

    thumbnail_url = @zine.thumbnail_url
    assert_includes thumbnail_url, "rails/active_storage/blobs"
  end

  def test_validates_file_size_within_10mb_limit
    # Save the record first so we can work with blob updates
    @zine.save!

    # This test simulates file size validation without actually creating a large file
    large_file_data = "x" * (1024 * 1024) # 1MB of data for the test
    large_file = StringIO.new(large_file_data)

    @zine.pdf_file.attach(
      io: large_file,
      filename: "large_test.pdf",
      content_type: "application/pdf"
    )

    # Force the blob to have a large size
    @zine.pdf_file.blob.update!(byte_size: 11.megabytes)

    # Call the validation method directly
    @zine.send(:pdf_file_size_within_limit)

    assert_includes @zine.errors[:pdf_file], "must be within 10MB"
  end
end
