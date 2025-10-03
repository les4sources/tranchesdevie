namespace :tenants do
  desc "Migrate all tenant schemas"
  task migrate: :environment do
    Tenant.find_each do |tenant|
      puts "Migrating tenant: #{tenant.subdomain}"
      MultiTenant.switch(tenant.subdomain) do
        ActiveRecord::Base.connection.migration_context.migrate
      end
    end
    puts "✅ All tenants migrated"
  end

  desc "Load schema structure into all tenant schemas"
  task load_schema: :environment do
    # Get all table definitions from public schema
    tables_sql = <<-SQL
      SELECT tablename FROM pg_tables 
      WHERE schemaname = 'public' 
      AND tablename NOT IN ('schema_migrations', 'ar_internal_metadata', 'tenants')
      ORDER BY tablename
    SQL
    
    tables = ActiveRecord::Base.connection.select_values(tables_sql)
    
    Tenant.find_each do |tenant|
      puts "Loading schema into tenant: #{tenant.subdomain}"
      
      MultiTenant.switch(tenant.subdomain) do
        # Copy each table structure from public to tenant schema
        tables.each do |table_name|
          # Get the CREATE TABLE statement from public schema
          create_sql = ActiveRecord::Base.connection.select_value(
            "SELECT pg_get_tabledef('public', '#{table_name}')"
          )
          
          # This is complex, so let's use a simpler approach:
          # Just run migrations in the tenant schema
          ActiveRecord::Base.connection.execute("SET search_path TO #{tenant.subdomain}")
          
          # Copy structure from public
          ActiveRecord::Base.connection.tables.each do |existing_table|
            ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{existing_table} CASCADE")
          end
          
          # Load the schema
          load Rails.root.join("db/schema.rb")
        end
      end
      
      puts "✅ Schema loaded into #{tenant.subdomain}"
    end
  end

  desc "Simplified: Copy public schema tables to tenant schemas using pg_dump"
  task copy_structure: :environment do
    Tenant.find_each do |tenant|
      puts "Copying structure to tenant: #{tenant.subdomain}"
      
      # Get list of tables to copy (exclude tenants table)
      tables = ActiveRecord::Base.connection.tables.reject { |t| t.in?(['schema_migrations', 'ar_internal_metadata', 'tenants']) }
      
      MultiTenant.switch(tenant.subdomain) do
        tables.each do |table|
          # Get the table definition
          structure = ActiveRecord::Base.connection.execute(
            "SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='#{table}'"
          ).to_a
          
          unless structure.empty?
            # Copy table structure
            ActiveRecord::Base.connection.execute(
              "CREATE TABLE IF NOT EXISTS #{tenant.subdomain}.#{table} (LIKE public.#{table} INCLUDING ALL)"
            )
          end
        end
      end
      
      puts "✅ Structure copied to #{tenant.subdomain}"
    end
  end
end
