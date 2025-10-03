# frozen_string_literal: true

# Middleware to automatically switch tenant based on subdomain
class TenantMiddleware
  EXCLUDED_SUBDOMAINS = %w[www admin api].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    subdomain = extract_subdomain(request)

    if subdomain.present? && !EXCLUDED_SUBDOMAINS.include?(subdomain)
      tenant = Tenant.find_by(subdomain: subdomain)

      if tenant
        MultiTenant.switch(tenant.subdomain) do
          @app.call(env)
        end
      else
        # Tenant not found, return 404 or redirect
        [404, { "Content-Type" => "text/html" }, ["Tenant not found"]]
      end
    else
      # No tenant context (public routes, admin, etc.)
      MultiTenant.reset
      @app.call(env)
    end
  ensure
    MultiTenant.reset
  end

  private

  def extract_subdomain(request)
    # Extract subdomain from host
    # For development with lvh.me: bakery.lvh.me:3000 -> "bakery"
    # For production: bakery.example.com -> "bakery"
    host = request.host
    return nil if host.nil?

    parts = host.split(".")
    return nil if parts.length < 2

    # For localhost or IP addresses, no subdomain
    return nil if host.match?(/^(\d{1,3}\.){3}\d{1,3}$/) || host == "localhost"

    # Return first part as subdomain
    parts.first unless parts.first == "www"
  end
end

