# Dropbox Integration Setup

This application uses Dropbox for remote file storage. Follow these steps to configure Dropbox integration:

## 1. Create a Dropbox App

1. Go to [Dropbox App Console](https://www.dropbox.com/developers/apps)
2. Click "Create app"
3. Choose these settings:
   - **API**: Choose "Scoped access"
   - **Access**: Choose "Full Dropbox" (needed to create folders and manage files)
   - **Name**: Enter a unique name for your app (e.g., "Zineshare-YourName")

## 2. Configure Permissions (Scopes)

In your app's settings, go to the "Permissions" tab and enable these scopes:

- `files.metadata.write` - View and edit information about your Dropbox files and folders
- `files.metadata.read` - View information about your Dropbox files and folders
- `files.content.write` - Edit content of your Dropbox files and folders
- `files.content.read` - View content of your Dropbox files and folders

Click "Submit" to save the permissions.

## 3. Generate Access Token

For development/testing:
1. In your app settings, go to the "Settings" tab
2. Under "OAuth 2", find the "Generated access token" section
3. Click "Generate" to create an access token
4. Copy this token - you'll need it for Rails credentials

## 4. Configure Rails Credentials

Edit your Rails credentials:

```bash
rails credentials:edit
```

Add the following:

```yaml
dropbox:
  access_token: your_generated_access_token_here
  app_key: your_app_key_here  # From app settings
  app_secret: your_app_secret_here  # From app settings
```

## 5. OAuth 2 Redirect URIs (for production)

If implementing OAuth flow for users:
1. In your app settings, add redirect URIs:
   - Development: `http://localhost:3000/auth/dropbox/callback`
   - Production: `https://yourdomain.com/auth/dropbox/callback`

## Environment Variables (Alternative)

You can also use environment variables instead of Rails credentials:

```bash
export DROPBOX_ACCESS_TOKEN="your_access_token"
export DROPBOX_APP_KEY="your_app_key"
export DROPBOX_APP_SECRET="your_app_secret"
```

## Testing the Integration

After configuration, test the integration:

1. Run the Rails server
2. Upload a zine
3. Check your Dropbox account for a "Zineshare Uploads" folder
4. Verify the PDF file appears in this folder

## Notes

- The access token generated in step 3 is for your account only
- For production, implement proper OAuth flow for user authentication
- Files are stored in `/Zineshare Uploads` folder in Dropbox
- The application automatically creates this folder if it doesn't exist