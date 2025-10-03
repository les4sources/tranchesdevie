# frozen_string_literal: true

# Multi-tenant module for PostgreSQL schema-based tenancy
# Compatible with Rails 8.x
module MultiTenant
  class TenantNotFound < StandardError; end
  class SchemaExists < StandardError; end

  class << self
    # Get current tenant schema
    def current
      Thread.current[:current_tenant_schema] || "public"
    end

    # Set current tenant schema
    def current=(schema_name)
      Thread.current[:current_tenant_schema] = schema_name
      switch!(schema_name) if schema_name.present?
    end

    # Switch to a specific tenant schema
    def switch!(schema_name)
      return if schema_name == current

      connection.schema_search_path = schema_name
      Thread.current[:current_tenant_schema] = schema_name
    end

    # Reset to default schema
    def reset
      switch!("public")
      Thread.current[:current_tenant_schema] = nil
    end

    # Execute code within a tenant context
    def switch(schema_name, &block)
      previous = current
      switch!(schema_name)
      yield
    ensure
      switch!(previous)
    end

    # Create a new tenant schema
    def create(schema_name)
      raise SchemaExists, "Schema '#{schema_name}' already exists" if schema_exists?(schema_name)

      connection.execute("CREATE SCHEMA #{connection.quote_table_name(schema_name)}")
    end

    # Drop a tenant schema
    def drop(schema_name)
      raise TenantNotFound, "Schema '#{schema_name}' does not exist" unless schema_exists?(schema_name)

      connection.execute("DROP SCHEMA #{connection.quote_table_name(schema_name)} CASCADE")
    end

    # Check if schema exists
    def schema_exists?(schema_name)
      sql = <<-SQL
        SELECT EXISTS(
          SELECT 1 FROM pg_namespace WHERE nspname = '#{schema_name}'
        )
      SQL
      connection.select_value(sql)
    end

    # List all tenant schemas
    def all
      sql = <<-SQL
        SELECT nspname
        FROM pg_namespace
        WHERE nspname NOT IN ('pg_toast', 'pg_catalog', 'information_schema', 'public')
        AND nspname NOT LIKE 'pg_%'
        ORDER BY nspname
      SQL
      connection.select_values(sql)
    end

    private

    def connection
      ActiveRecord::Base.connection
    end
  end
end

