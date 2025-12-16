# frozen_string_literal: true

# rubocop:disable Rails/Output

# Seeds for development and demo purposes
# Run: bin/rails db:seed

puts "🌱 Seeding database..."

# Create demo user
demo_user = User.find_or_create_by!(email: "demo@auditron.dev") do |user|
  user.password = "password123"
end
puts "✓ Demo user: #{demo_user.email}"

# Create API key for demo user (only if none exist)
if demo_user.api_keys.empty?
  api_key = demo_user.api_keys.create!(name: "Demo API Key", expires_at: 1.year.from_now)
  puts "✓ API Key created: #{api_key.raw_token}"
  puts ""
  puts "=" * 60
  puts "📋 SAVE THIS API KEY - It won't be shown again!"
  puts "   Token: #{api_key.raw_token}"
  puts "=" * 60
else
  puts "✓ API key already exists for demo user"
end

puts ""
puts "🎉 Seeding complete!"

# rubocop:enable Rails/Output
