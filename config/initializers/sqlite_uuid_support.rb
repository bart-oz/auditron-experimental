# frozen_string_literal: true

# Enable UUID support for SQLite in ActiveRecord
require "active_record/connection_adapters/sqlite3_adapter"

# Register UUID type for SQLite3 adapter (maps to String behavior)
ActiveRecord::Type.register(:uuid, ActiveRecord::Type::String, adapter: :sqlite3)

# Extend SQLite3 adapter to recognize UUID as a native type
module SqliteUuidNativeType
  def native_database_types
    super.merge(uuid: { name: "TEXT" })
  end
end

ActiveRecord::ConnectionAdapters::SQLite3Adapter.prepend(SqliteUuidNativeType)
