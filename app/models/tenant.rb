class Tenant < ApplicationRecord
  # Validations
  validates :name, presence: true
  validates :subdomain, presence: true,
                        uniqueness: { case_sensitive: false },
                        format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/,
                                  message: "only allows lowercase letters, numbers, and hyphens" },
                        exclusion: { in: %w[www admin api app],
                                     message: "%{value} is reserved" }

  # Callbacks
  after_create :create_schema
  before_destroy :drop_schema

  private

  def create_schema
    MultiTenant.create(subdomain)
  rescue StandardError => e
    errors.add(:base, "Failed to create tenant schema: #{e.message}")
    raise "Failed to create tenant schema: #{e.message}"
  end

  def drop_schema
    MultiTenant.drop(subdomain)
  rescue StandardError => e
    Rails.logger.error "Failed to drop schema for tenant #{subdomain}: #{e.message}"
    # Don't prevent deletion of the tenant record even if schema drop fails
  end
end
