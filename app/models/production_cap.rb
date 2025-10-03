class ProductionCap < ApplicationRecord
  # Associations
  belongs_to :bake_day
  belongs_to :product_variant

  # Validations
  validates :capacity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :reserved, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :product_variant_id, uniqueness: { scope: :bake_day_id }
  validate :reserved_not_greater_than_capacity

  # Delegations
  delegate :baked_on, :day_of_week, :tuesday?, :friday?, to: :bake_day, prefix: false
  delegate :display_name, to: :product_variant, prefix: true

  # Scopes
  scope :with_capacity, -> { where("capacity > reserved") }
  scope :at_capacity, -> { where("capacity <= reserved") }
  scope :for_upcoming_bakes, -> { joins(:bake_day).merge(BakeDay.upcoming) }

  # Instance methods
  def available
    capacity - reserved
  end

  def available?
    available > 0
  end

  def at_capacity?
    reserved >= capacity
  end

  def percentage_reserved
    return 0 if capacity.zero?
    ((reserved.to_f / capacity) * 100).round(1)
  end

  # Reserve units with pessimistic row-level locking (SELECT FOR UPDATE)
  # This prevents race conditions during concurrent capacity allocation
  # Uses database-level locking to ensure atomicity
  #
  # @param quantity [Integer] Number of units to reserve
  # @return [Boolean] true if successful, false if insufficient capacity
  # @raise [ActiveRecord::LockWaitTimeout] if lock cannot be acquired
  def reserve!(quantity)
    return false if quantity <= 0
    
    with_lock do
      if available >= quantity
        increment!(:reserved, quantity)
        true
      else
        false
      end
    end
  rescue ActiveRecord::LockWaitTimeout => e
    Rails.logger.error("Lock timeout while reserving capacity: #{e.message}")
    raise
  end

  # Reserve units with retry logic for handling lock timeouts
  # Attempts multiple times before giving up
  #
  # @param quantity [Integer] Number of units to reserve
  # @param max_retries [Integer] Maximum number of retry attempts (default: 3)
  # @return [Boolean] true if successful, false if insufficient capacity or max retries exceeded
  def reserve_with_retry!(quantity, max_retries: 3)
    retries = 0
    begin
      reserve!(quantity)
    rescue ActiveRecord::LockWaitTimeout
      retries += 1
      if retries < max_retries
        sleep(0.1 * retries) # Exponential backoff
        retry
      else
        Rails.logger.error("Max retries exceeded while reserving capacity for production_cap #{id}")
        false
      end
    end
  end

  # Release reserved units with row-level locking
  #
  # @param quantity [Integer] Number of units to release
  # @return [Boolean] true if successful, false if invalid quantity
  def release!(quantity)
    return false if quantity <= 0
    
    with_lock do
      if reserved >= quantity
        decrement!(:reserved, quantity)
        true
      else
        false
      end
    end
  rescue ActiveRecord::LockWaitTimeout => e
    Rails.logger.error("Lock timeout while releasing capacity: #{e.message}")
    raise
  end

  # Handle optimistic locking conflicts
  # Called when a StaleObjectError is raised during concurrent updates
  def self.handle_stale_object_error
    yield
  rescue ActiveRecord::StaleObjectError => e
    Rails.logger.warn("Optimistic lock conflict detected: #{e.message}")
    raise
  end

  private

  def reserved_not_greater_than_capacity
    return if reserved.nil? || capacity.nil?
    
    if reserved > capacity
      errors.add(:reserved, "cannot be greater than capacity")
    end
  end
end
