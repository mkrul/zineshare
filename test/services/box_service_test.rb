require "test_helper"

class BoxServiceTest < ActiveSupport::TestCase
  def test_box_error_inheritance
    assert BoxService::BoxError < StandardError
    assert BoxService::BoxUploadError < BoxService::BoxError
    assert BoxService::BoxAuthenticationError < BoxService::BoxError
  end

  def test_zines_folder_name_constant
    assert_equal 'Zineshare Uploads', BoxService::ZINES_FOLDER_NAME
  end

  def test_box_service_class_exists
    # Test that BoxService class exists and has expected methods
    assert defined?(BoxService)
    assert BoxService.respond_to?(:new)
  end

  def test_instance_methods_exist
    # Test that required instance methods are defined
    required_methods = [
      :upload_zine_file,
      :get_file_download_url,
      :delete_file,
      :file_exists?
    ]

    required_methods.each do |method_name|
      assert BoxService.instance_methods.include?(method_name),
             "BoxService should have #{method_name} method"
    end
  end

  def test_private_methods_exist
    # Test that required private methods are defined
    private_methods = [
      :create_client,
      :access_token,
      :ensure_zines_folder_exists
    ]

    private_methods.each do |method_name|
      assert BoxService.private_instance_methods.include?(method_name),
             "BoxService should have private #{method_name} method"
    end
  end

  def test_error_classes_are_defined
    # Test that all error classes are properly defined
    assert defined?(BoxService::BoxError)
    assert defined?(BoxService::BoxUploadError)
    assert defined?(BoxService::BoxAuthenticationError)
  end
end