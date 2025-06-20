# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create categories for zines
categories = [
  "Art & Illustration",
  "Poetry & Literature",
  "Music & Sound",
  "Photography",
  "Comics & Graphic Novels",
  "Personal Stories",
  "Experimental",
  "Punk Culture",
  "Animal Welfare",
  "Environment & Sustainability",
  "Feminism",
  "Anti-Capitalism",
  "Anarchism",
  "Anti-Fascism",
  "Anti-Racism",
  "Anti-War",
  "Anti-Imperialism",
  "LGBTQ+",
  "Science & Technology",
  "History & Culture",
  "Food & Cooking",
  "Travel & Exploration",
  "General Politics & Activism",
  "Prepping & Survivalism",
  "Health & Wellness",
  "DIY & Crafts",
  "Gardening & Farming",
  "Spirituality & Religion",
  "Technology & Gadgets",
  "Video Games & Pop Culture",
  "Writing & Publishing",
  "Other"
]

categories.each do |category_name|
  Category.find_or_create_by(name: category_name)
end

puts "Created #{Category.count} categories"

# Create admin user
admin_email = Rails.application.credentials.admin_email
admin_user = User.find_or_create_by(email: admin_email) do |user|
  user.password = Rails.application.credentials.admin_password
  user.admin = true
end
if admin_user.persisted?
  puts "Admin user created with email: #{admin_user.email}"
else
  puts "Admin user already exists: #{admin_user.email}"
end
