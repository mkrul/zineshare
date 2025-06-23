#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== VERIFYING DROPBOX SCOPES ==="
puts ""

begin
  # Get credentials
  access_token = Rails.application.credentials.dropbox&.access_token || ENV['DROPBOX_ACCESS_TOKEN']

  unless access_token.present?
    puts "❌ No access token found"
    exit 1
  end

  puts "✅ Access token found"

  # Initialize client
  require 'dropbox_api'
  client = DropboxApi::Client.new(access_token)
  puts "✅ Dropbox client created"

  # Test account access
  account = client.get_current_account
  puts "✅ Account access: #{account.name.display_name}"

  # Test file metadata read (list root folder)
  puts ""
  puts "Testing required scopes:"

  begin
    client.list_folder('')
    puts "✅ files.metadata.read - Can read folder metadata"
  rescue => e
    puts "❌ files.metadata.read - Cannot read folder metadata: #{e.message}"
  end

  # Test file metadata write (create a test folder)
  test_folder_name = '/Test Folder - Delete Me'
  begin
    client.create_folder(test_folder_name)
    puts "✅ files.metadata.write - Can create folders"

    # Clean up test folder
    client.delete(test_folder_name)
    puts "✅ files.metadata.write - Can delete folders"
  rescue => e
    puts "❌ files.metadata.write - Cannot create/delete folders: #{e.message}"
  end

  puts ""
  puts "=== SCOPE VERIFICATION COMPLETE ==="
  puts ""
  puts "If you see any ❌ errors above, you need to:"
  puts "1. Go to https://www.dropbox.com/developers/apps"
  puts "2. Select your app"
  puts "3. Go to Permissions tab"
  puts "4. Enable these scopes:"
  puts "   - files.metadata.write"
  puts "   - files.metadata.read"
  puts "   - files.content.write"
  puts "   - files.content.read"
  puts "5. Click Submit"
  puts "6. Generate a new access token"
  puts "7. Update your Rails credentials with the new token"

rescue => e
  puts "❌ Error: #{e.class} - #{e.message}"
  puts ""
  puts "This error suggests scope/permission issues."
  puts "Follow the steps above to add required scopes to your Dropbox app."
end