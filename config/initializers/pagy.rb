# frozen_string_literal: true

# Pagy v43+ configuration
# See https://ddnexus.github.io/pagy/resources/initializer/

Pagy.options[:limit] = 25              # Items per page
Pagy.options[:client_max_limit] = 100  # Max items per page when client requests
