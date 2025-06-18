# Zineshare

A Rails application for sharing creative zines in PDF format.

## Features

### Zine Upload & PDF Validation

- **Open submission**: No login required for uploading zines
- **PDF validation**: Validates uploaded files are PDFs with exact dimensions of 1224×1584 pixels
- **Metadata stripping**: Framework in place for removing PDF metadata (currently logs for implementation)
- **Category system**: Zines can be categorized using predefined categories
- **Approval workflow**: All uploads are marked as unapproved by default until admin review
- **Creator attribution**: "Created by" field for attributing zine creators

### Zine Browsing & Discovery

- **Thumbnail gallery**: Beautiful grid layout with automatically generated PDF thumbnails
- **Category filtering**: Filter zines by category with instant results
- **Infinite scrolling**: Seamless loading of more zines as you scroll down
- **Responsive design**: Optimized viewing experience on all device sizes
- **Visual indicators**: Clear status indicators for file availability

### Remote Storage on Box.com

- **Cloud storage**: All PDF files are automatically uploaded to Box.com for remote storage
- **Local cleanup**: Files are removed from local server storage after successful Box upload
- **Robust error handling**: Graceful fallback if Box upload fails
- **Secure access**: Files are served through Box.com's secure download URLs
- **Automatic folder management**: Creates and manages a dedicated "Zineshare Uploads" folder

### Technical Implementation

- **Models**: `Zine` and `Category` with proper validations and associations
- **File handling**: Uses Rails Active Storage with Box.com integration
- **PDF processing**: Uses `pdf-reader` gem for dimension validation
- **Thumbnail generation**: Automatic PDF-to-image conversion using MiniMagick
- **Box.com API**: Uses Boxr gem for seamless Box.com integration
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

### Browsing Zines

1. Visit the homepage to see the zine gallery
2. Use the category filter to narrow down results
3. Scroll down to automatically load more zines
4. Click on any zine thumbnail to view the full PDF

### Uploading a Zine

1. Click "Upload Zine" from the navigation or homepage
2. Fill in the creator name
3. Select a category
4. Upload a PDF file (must be exactly 1224×1584 pixels)
5. Submit the form
6. File is automatically uploaded to Box.com and thumbnail generated

### Viewing Zines

- Click on any zine card to view the full PDF
- PDFs are served from Box.com secure storage
- Files can be viewed inline or downloaded
- Thumbnails provide quick visual previews

## Development

### Running Tests

```bash
bin/rails test
```

Note: Box.com integration and thumbnail generation are disabled in test environment for easier testing.

### Key Files

- `app/models/zine.rb` - Main zine model with PDF validation, Box integration, and thumbnails
- `app/models/category.rb` - Category model
- `app/services/box_service.rb` - Box.com API integration service
- `app/controllers/zines_controller.rb` - Zine upload, display, and filtering logic
- `app/views/zines/` - Views for zine interface with pagination and filtering
- `app/javascript/controllers/` - Stimulus controllers for infinite scroll and filtering
- `config/initializers/pagy.rb` - Pagination configuration
- `config/initializers/box.rb` - Box.com configuration
- `db/seeds.rb` - Initial category data

## Production Considerations

For production deployment, consider:

1. **Box.com Setup**: Configure proper Box.com app with JWT authentication for production
2. **ImageMagick**: Ensure ImageMagick is installed on production servers for thumbnail generation
3. **PDF Metadata Stripping**: Implement actual metadata removal during Box upload
4. **Thumbnail Storage**: Consider CDN for thumbnail delivery and caching
5. **Admin Interface**: Add admin panel for approving/managing zines
6. **File Size Limits**: Configure appropriate upload size limits
7. **Security**: Add rate limiting and virus scanning for uploads
8. **Monitoring**: Monitor Box.com API usage and rate limits
9. **Performance**: Optimize thumbnail generation and consider background processing
10. **Backup Strategy**: Consider backup strategies for Box.com stored files

## Dependencies

- Rails 8.0+
- PostgreSQL
- Active Storage
- pdf-reader gem for PDF processing
- prawn gem for PDF generation (testing)
- boxr gem for Box.com API integration
- pagy gem for efficient pagination
- mini_magick gem for thumbnail generation
- ImageMagick system dependency

## Architecture

### File Storage Flow

1. User uploads PDF through web interface
2. File is temporarily stored using Active Storage
3. PDF dimensions and format are validated
4. Thumbnail is generated from first page of PDF
5. File is uploaded to Box.com via API
6. Box file ID is stored in database
7. Local temporary file is removed
8. Future access uses Box.com download URLs

### Browsing & Filtering Flow

1. User visits homepage with paginated zine grid
2. Category filter allows real-time filtering
3. Infinite scroll automatically loads more content
4. Thumbnails provide visual preview of each zine
5. Stimulus controllers handle dynamic interactions

### Error Handling

- Box upload failures are logged and handled gracefully
- Thumbnail generation failures don't prevent zine creation
- Users receive appropriate feedback for upload issues
- Files remain in local storage as fallback if Box upload fails
- Robust retry mechanisms for transient API failures
