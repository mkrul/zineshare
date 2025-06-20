# Zineshare

A Rails application for sharing creative zines in PDF format with user authentication, personal dashboards, and comprehensive zine management.

## Features

### User Authentication & Registration

- **User registration**: Create accounts with email and password (8+ characters minimum)
- **Secure login/logout**: Industry-standard authentication with Devise
- **Personal dashboard**: Users can view and manage their uploaded zines
- **Session management**: Secure cookie-based sessions with CSRF protection
- **Password recovery**: Email-based password reset functionality
- **Responsive forms**: Beautiful, mobile-friendly authentication interface

### Zine Upload & Management

- **Authenticated uploads**: User login required for uploading zines
- **Title & metadata**: Each zine requires a title (max 100 chars) and creator name
- **PDF validation**: Validates uploaded files are PDFs with exact dimensions of 1224×1584 pixels
- **File size limits**: Enforces 10MB maximum file size for PDF uploads
- **PDF replacement**: Users can update existing zines with new PDF files
- **Metadata stripping**: Framework in place for removing PDF metadata (currently logs for implementation)
- **Category system**: Zines can be categorized using predefined categories
- **Creator attribution**: "Created by" field for attributing zine creators
- **User association**: Uploaded zines are automatically linked to the user's account
- **Edit capabilities**: Users can update title, creator, category, and replace PDF files
- **Delete functionality**: Users can permanently delete their own zines with confirmation dialog
- **Ownership protection**: Users can only edit and delete their own zines

### Admin Management & Content Moderation

- **Admin role system**: Boolean admin flag on users with proper authorization
- **Content moderation**: Pending moderation system for reviewing zine submissions
- **Admin dashboard**: Comprehensive interface for managing all zines and users
- **Approval workflow**: Admins can approve, reject, or delete any zine content
- **Statistics overview**: Real-time counts of pending, approved, and total zines
- **Batch operations**: Efficient management of multiple zines with confirmation dialogs
- **File cleanup**: Automatic Box.com file deletion when rejecting or deleting zines
- **Audit trail**: Clear logging of all admin actions and moderation decisions

### Admin Notifications

- **Upload notifications**: Admins receive email notifications for all new zine uploads
- **Rich email templates**: Both HTML and text email formats with zine details
- **User information**: Includes uploader email and zine metadata in notifications
- **Configurable recipients**: Uses `Rails.application.credentials.admin_email` with fallback
- **Non-blocking**: Email failures don't prevent zine uploads from succeeding

### Zine Browsing & Discovery

- **Thumbnail gallery**: Beautiful grid layout with automatically generated PDF thumbnails
- **Title-first display**: Zine titles are prominently displayed with creator attribution
- **Category filtering**: Filter zines by category with instant results
- **Infinite scrolling**: Seamless loading of more zines as you scroll down
- **Responsive design**: Optimized viewing experience on all device sizes
- **Visual indicators**: Clear status indicators for file availability
- **Content filtering**: Only approved zines appear in public listings
- **Moderation status**: Users can see the moderation status of their own zines

### Remote Storage on Box.com

- **Cloud storage**: All PDF files are automatically uploaded to Box.com for remote storage
- **Local cleanup**: Files are removed from local server storage after successful Box upload
- **File replacement**: Old Box.com files are automatically deleted when PDFs are replaced
- **Robust error handling**: Graceful fallback if Box upload fails
- **Secure access**: Files are served through Box.com's secure download URLs
- **Automatic folder management**: Creates and manages a dedicated "Zineshare Uploads" folder

### Personal Dashboard

- **Upload management**: View, edit, and delete your uploaded zines
- **Statistics tracking**: Monitor your total uploads and activity
- **Grid and list views**: Toggle between visual grid and detailed table layouts
- **Quick actions**: Easy access to upload new zines or browse the community gallery
- **Thumbnail previews**: Visual previews of your zines with upload dates
- **Direct editing**: Edit zine metadata and replace PDFs directly from dashboard
- **Safe deletion**: Delete zines with confirmation dialog and automatic file cleanup
- **Moderation status**: Clear indicators showing "Pending Review" or "Live" status
- **Content visibility**: See all your zines regardless of moderation status

### Technical Implementation

- **User Authentication**: Devise-powered authentication with email/password and admin roles
- **Models**: `User`, `Zine`, and `Category` with comprehensive validations and associations
- **Authorization**: Route-level authentication filters and ownership-based permissions
- **Admin System**: Role-based access control with comprehensive admin dashboard
- **Content Moderation**: Pending moderation system with approval/rejection workflow
- **User Dashboard**: Personal interface for managing uploaded zines with edit/delete capabilities
- **File handling**: Uses Rails Active Storage with Box.com integration and file replacement
- **PDF processing**: Uses `pdf-reader` gem for dimension validation and file size checking
- **Thumbnail generation**: Automatic PDF-to-image conversion using MiniMagick with regeneration
- **Box.com API**: Uses Boxr gem for seamless Box.com integration with cleanup on updates
- **Email notifications**: ActionMailer integration for admin notifications
- **Pagination**: Efficient pagination with Pagy gem for infinite scrolling
- **Modern UI**: Clean, responsive interface with Stimulus controllers
- **Comprehensive testing**: Full test coverage following Rails best practices

## Setup

1. Install dependencies:
   ```bash
   bundle install
   ```

2. Setup database:
   ```bash
   bin/rails db:setup
   ```

3. Configure Box.com credentials (see Box.com Configuration below)

4. Install ImageMagick (required for thumbnail generation):
   ```bash
   # macOS with Homebrew
   brew install imagemagick

   # Ubuntu/Debian
   sudo apt-get install imagemagick

   # CentOS/RHEL
   sudo yum install imagemagick
   ```

5. Start the server:
   ```bash
   bin/rails server
   ```

## Box.com Configuration

### Option 1: Rails Credentials (Recommended)

```bash
rails credentials:edit
```

Add to your credentials file:
```yaml
box:
  access_token: your_box_access_token_here
```

### Option 2: Environment Variables

```bash
export BOX_ACCESS_TOKEN=your_box_access_token_here
```

### Getting Box.com API Credentials

1. Go to [Box Developer Console](https://developer.box.com/)
2. Create a new app or use an existing one
3. Choose "Custom App" and "Server Authentication (JWT)" or "OAuth 2.0"
4. Get your access token from the app configuration
5. Ensure your app has the following scopes:
   - Read all files and folders stored in Box
   - Write all files and folders stored in Box
   - Manage users

See `config/box_credentials_example.yml` for detailed configuration instructions.

## Usage

### Getting Started

1. **Create an account**: Click "Sign Up" to register with your email and password
2. **Sign in**: Use "Sign In" to access your account and dashboard
3. **Access dashboard**: After signing in, you'll be redirected to your personal dashboard

### User Dashboard

- **View your zines**: See all zines you've uploaded with thumbnails and metadata
- **Upload statistics**: Track your total uploads and activity
- **Quick actions**: Easy access to upload new zines or browse the community gallery
- **Account management**: Update your profile and account settings

### Browsing Zines

1. Visit the homepage to see the zine gallery (accessible to all users)
2. Use the category filter to narrow down results
3. Scroll down to automatically load more zines
4. Click on any zine thumbnail to view the full PDF

### Uploading a Zine

1. **Sign in required**: You must be logged in to upload zines
2. Click "Upload Zine" from the navigation or dashboard
3. Fill in the required information:
   - **Title**: Enter a descriptive title for your zine (required, max 100 characters)
   - **Creator name**: Specify the creator or author name
   - **Category**: Select from predefined categories
   - **PDF file**: Upload a PDF file (must be exactly 1224×1584 pixels, max 10MB)
4. Submit the form - the zine will be associated with your account
5. File is automatically uploaded to Box.com and thumbnail generated
6. Admins receive email notifications about new uploads

### Editing Your Zines

1. **Access via dashboard**: Go to your personal dashboard to see all your zines
2. Click "Edit" on any zine you've uploaded
3. **Update metadata**: Change title, creator name, or category as needed
4. **Replace PDF (optional)**: Upload a new PDF file to replace the existing one
   - **Warning**: Uploading a new PDF permanently replaces the old file
   - Old file is automatically deleted from Box.com storage
   - New thumbnail is automatically generated
5. **View changes**: Updated zines immediately reflect your changes
6. **Ownership protection**: You can only edit zines you've uploaded

### Managing Your Zines

- **Dashboard views**: Toggle between grid view (visual thumbnails) and list view (detailed table)
- **Quick actions**: View, edit, or delete your zines directly from the dashboard
- **Upload statistics**: Track your total uploads and activity
- **Secure deletion**: Deleting a zine removes it from both the database and Box.com storage

### Deleting Your Zines

1. **Access via dashboard or zine detail page**: Delete buttons available in both locations for your zines
2. **Confirmation required**: JavaScript confirmation dialog prevents accidental deletions
   - Warning: "Are you sure you want to delete this zine? This action cannot be undone."
3. **Complete cleanup**: Deletion removes:
   - Database record
   - PDF file from Box.com storage
   - Generated thumbnail images
   - All associated metadata
4. **Immediate feedback**: Redirects to dashboard with "Your zine has been deleted" message
5. **Ownership protection**: You can only delete zines you've uploaded
6. **404 handling**: Deleted zines properly return "not found" when accessed by URL

### Viewing Zines

- Click on any zine card to view the full PDF
- PDFs are served from Box.com secure storage
- Files can be viewed inline or downloaded
- Thumbnails provide quick visual previews
- All zines display titles prominently with creator attribution

### Admin Content Management

**Admin Access:**
1. **Admin account required**: Contact system administrator for admin privileges
2. **Admin login**: Sign in with admin credentials (default: admin@zineshare.com / admin123456)
3. **Admin navigation**: Red "Admin" button appears in navigation for admin users only

**Admin Dashboard:**
1. **Statistics overview**: View pending, approved, and total zine counts at a glance
2. **Comprehensive listing**: See all zines with status indicators and user information
3. **Visual prioritization**: Pending zines highlighted with yellow background for quick identification
4. **Responsive interface**: Mobile-friendly admin tools for managing content anywhere

**Content Moderation:**
1. **Approve zines**: Click "Approve" to make pending zines visible to the public
   - Removes pending moderation flag
   - Zine immediately appears in public listings
   - User receives confirmation via status change in dashboard
2. **Reject submissions**: Click "Reject" to permanently delete inappropriate content
   - Complete removal from database and Box.com storage
   - Automatic file cleanup prevents orphaned files
   - Action cannot be undone - use with caution
3. **Delete any zine**: Admin delete button available for all zines regardless of status
   - Removes problematic content that slipped through approval
   - Complete cleanup including thumbnails and metadata
   - Clear audit trail via admin notification system

**Security & Authorization:**
- **Role verification**: All admin actions require authenticated admin user
- **Access control**: Non-admin users redirected with clear error messages
- **Confirmation dialogs**: All destructive actions require explicit confirmation
- **Audit logging**: All admin actions logged for transparency and accountability

## Email Configuration

For admin notifications to work properly, configure the admin email address:

### Rails Credentials (Recommended)

```bash
rails credentials:edit
```

Add to your credentials file:
```yaml
admin_email: admin@yoursite.com
```

### Fallback

If no admin email is configured, notifications default to `admin@zineshare.com`.

## Development

### Running Tests

```bash
bin/rails test
```

Note: Box.com integration and thumbnail generation are disabled in test environment for easier testing.

### Key Files

- `app/models/user.rb` - User model with Devise authentication
- `app/models/zine.rb` - Main zine model with PDF validation, Box integration, thumbnails, and file size limits
- `app/models/category.rb` - Category model
- `app/controllers/users_controller.rb` - User dashboard and profile management
- `app/controllers/zines_controller.rb` - Zine CRUD operations with edit/update/delete and ownership protection
- `app/controllers/admin_controller.rb` - Admin dashboard and content moderation system
- `app/controllers/application_controller.rb` - Authentication redirects and base controller logic
- `app/mailers/admin_notification_mailer.rb` - Email notifications for new zine uploads
- `app/services/box_service.rb` - Box.com API integration service with file replacement
- `app/views/users/dashboard.html.erb` - User dashboard interface with zine management and status indicators
- `app/views/admin/index.html.erb` - Admin dashboard for content moderation and management
- `app/views/zines/new.html.erb` - Zine upload form with title and file size validation
- `app/views/zines/edit.html.erb` - Zine editing form with PDF replacement capability
- `app/views/admin_notification_mailer/` - Email templates for admin notifications
- `app/views/devise/` - Authentication forms (login, registration, password reset)
- `app/views/zines/` - Views for zine interface with pagination and filtering
- `app/javascript/controllers/` - Stimulus controllers for infinite scroll and filtering
- `config/initializers/devise.rb` - Devise authentication configuration
- `config/initializers/pagy.rb` - Pagination configuration
- `config/initializers/box.rb` - Box.com configuration
- `db/seeds.rb` - Initial category data and admin user creation

## Production Considerations

For production deployment, consider:

1. **Box.com Setup**: Configure proper Box.com app with JWT authentication for production
2. **Email Configuration**: Set up proper SMTP settings and configure admin email addresses
3. **ImageMagick**: Ensure ImageMagick is installed on production servers for thumbnail generation
4. **File Size Limits**: The 10MB PDF limit is enforced at application level - ensure server upload limits accommodate
5. **PDF Metadata Stripping**: Implement actual metadata removal during Box upload
6. **Thumbnail Storage**: Consider CDN for thumbnail delivery and caching
7. **Admin Setup**: Configure admin user credentials and ensure admin email notifications work
8. **Content Moderation**: Establish content policies and train admin users on moderation workflow
9. **Security**: Add rate limiting and virus scanning for uploads
10. **Performance**: Optimize thumbnail generation and consider background processing for large files
11. **Box.com Management**: Monitor API usage, implement file cleanup policies, and consider backup strategies
12. **User Permissions**: Comprehensive role-based authorization system already implemented
13. **Email Delivery**: Configure reliable email service for admin notifications (SendGrid, etc.)
14. **Admin Audit**: Consider implementing detailed admin action logging for compliance

## Dependencies

- Rails 8.0+
- PostgreSQL
- Devise gem for user authentication
- Active Storage
- pdf-reader gem for PDF processing
- prawn gem for PDF generation (testing)
- boxr gem for Box.com API integration
- pagy gem for efficient pagination
- mini_magick gem for thumbnail generation
- ActionMailer for admin notifications
- ImageMagick system dependency

## Architecture

### User Authentication Flow

1. User visits sign-up page and creates account with email/password
2. Account is immediately active (no email confirmation required)
3. User is automatically signed in and redirected to personal dashboard
4. Subsequent sign-ins redirect to dashboard showing user's zines
5. Protected routes (like zine upload) require authentication
6. Users can securely sign out with session destruction

### File Storage Flow

1. User must be authenticated to upload files
2. User uploads PDF through web interface
3. File is temporarily stored using Active Storage
4. PDF dimensions and format are validated
5. Thumbnail is generated from first page of PDF
6. File is uploaded to Box.com via API
7. Zine is associated with the current user
8. Box file ID is stored in database
9. Local temporary file is removed
10. Future access uses Box.com download URLs

### Browsing & Filtering Flow

1. User visits homepage with paginated zine grid (no authentication required)
2. Only approved zines appear in public listings (pending zines filtered out)
3. Category filter allows real-time filtering
4. Infinite scroll automatically loads more content
5. Thumbnails provide visual preview of each zine
6. Stimulus controllers handle dynamic interactions
7. Authenticated users can access their personal dashboard
8. Admin users see additional admin navigation and can access moderation tools

### Error Handling

- Authentication failures redirect to sign-in with clear error messages
- Box upload failures are logged and handled gracefully
- Thumbnail generation failures don't prevent zine creation
- Users receive appropriate feedback for upload issues
- Files remain in local storage as fallback if Box upload fails
- Robust retry mechanisms for transient API failures

## Implementation Status

### ✅ Completed Features

All core functionality has been implemented:

- **Zine Upload & Management**: Full CRUD operations with title fields, file size validation (10MB), and PDF replacement
- **User Authentication**: Complete user registration, login, and dashboard system with admin roles
- **Admin Content Moderation**: Comprehensive admin dashboard with approval/rejection workflow
- **Admin Notifications**: Email notifications for new uploads with rich HTML/text templates
- **Box.com Integration**: Secure cloud storage with automatic file cleanup on updates
- **Thumbnail Generation**: Automatic PDF thumbnails with regeneration on file replacement
- **User Authorization**: Ownership-based permissions and role-based admin access control
- **Content Filtering**: Public listings show only approved content with moderation system
- **Responsive UI**: Modern, mobile-friendly interface with grid/list dashboard views and admin tools

### Architecture Overview

The application implements a complete zine sharing workflow with content moderation:

1. **User Registration** → Users create accounts and access personal dashboards
2. **Zine Upload** → Authenticated users upload PDFs with titles and metadata
3. **File Processing** → PDFs are validated, thumbnails generated, and files stored on Box.com
4. **Admin Notification** → Admins receive email alerts about new uploads
5. **Content Moderation** → Admins review and approve/reject submissions via admin dashboard
6. **Public Browsing** → All users can browse approved zines with filtering and infinite scroll
7. **Content Management** → Users can edit metadata, replace PDFs, or delete their zines
8. **Admin Management** → Admins can moderate, approve, reject, or delete any content
9. **Secure Storage** → All files managed through Box.com with automatic cleanup


