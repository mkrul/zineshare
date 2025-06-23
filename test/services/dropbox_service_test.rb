require "test_helper"

class DropboxServiceTest < ActiveSupport::TestCase
  def test_dropbox_error_inheritance
    assert DropboxService::DropboxError < StandardError
    assert DropboxService::DropboxUploadError < DropboxService::DropboxError
    assert DropboxService::DropboxAuthenticationError < DropboxService::DropboxError
  end

  def test_zines_folder_path_constant
    assert_equal '/Zineshare Uploads', DropboxService::ZINES_FOLDER_PATH
  end

  def test_dropbox_service_class_exists
    # Test that DropboxService class exists and has expected methods
    assert defined?(DropboxService)
    assert DropboxService.respond_to?(:new)
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
      assert DropboxService.instance_methods.include?(method_name),
             "DropboxService should have #{method_name} method"
    end
  end

  def test_private_methods_exist
    # Test that required private methods are defined
    private_methods = [
      :create_client,
      :ensure_zines_folder_exists
    ]

    private_methods.each do |method_name|
      assert DropboxService.private_instance_methods.include?(method_name),
             "DropboxService should have private #{method_name} method"
    end
  end

  def test_error_classes_are_defined
    # Test that all error classes are properly defined
    assert defined?(DropboxService::DropboxError)
    assert defined?(DropboxService::DropboxUploadError)
    assert defined?(DropboxService::DropboxAuthenticationError)
  end
end