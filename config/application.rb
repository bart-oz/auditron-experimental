require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"

Bundler.require(*Rails.groups)

module Auditron
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])
    config.api_only = true
    config.engines_loading_behavior = :add if !Rails.env.test? # Skip litestream engine loading in test environment to avoid protect_from_forgery conflicts
    config.active_record.schema_format = :sql # Use SQL format for schema dump (SQLite + UUIDs workaround)
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end
  end
end
