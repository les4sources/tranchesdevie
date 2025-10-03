# Service for managing production capacity allocation and validation
# Handles capacity checks, reservations, and releases with proper error handling
class CapacityManager
  class InsufficientCapacityError < StandardError; end
  class InvalidQuantityError < StandardError; end
  class CapacityNotFoundError < StandardError; end

  attr_reader :product_variant, :bake_day

  def initialize(product_variant, bake_day)
    @product_variant = product_variant
    @bake_day = bake_day
  end

  # Find or create production cap for this variant and bake day
  def production_cap
    @production_cap ||= ProductionCap.find_or_initialize_by(
      product_variant: product_variant,
      bake_day: bake_day
    )
  end

  # Check if capacity is configured
  def capacity_configured?
    production_cap.persisted? && production_cap.capacity > 0
  end

  # Get available capacity
  def available_capacity
    return Float::INFINITY unless capacity_configured?
    production_cap.available
  end

  # Check if a specific quantity is available
  def available?(quantity)
    return false if quantity <= 0
    available_capacity >= quantity
  end

  # Allocate capacity for an order (with row-level locking and retry logic)
  # Uses pessimistic locking (SELECT FOR UPDATE) to prevent race conditions
  # during concurrent capacity allocation
  #
  # @param quantity [Integer] Number of units to allocate
  # @param use_retry [Boolean] Whether to use retry logic for lock timeouts (default: true)
  # @return [Boolean] true if successful
  # @raise [CapacityNotFoundError] if no capacity is configured
  # @raise [InsufficientCapacityError] if requested quantity exceeds available capacity
  # @raise [ActiveRecord::LockWaitTimeout] if lock cannot be acquired (when use_retry is false)
  def allocate!(quantity, use_retry: true)
    validate_quantity!(quantity)
    
    return true unless capacity_configured?
    
    unless production_cap.persisted?
      raise CapacityNotFoundError, "No capacity configured for #{product_variant.display_name} on #{bake_day.display_name}"
    end

    success = if use_retry
      production_cap.reserve_with_retry!(quantity)
    else
      production_cap.reserve!(quantity)
    end
    
    unless success
      raise InsufficientCapacityError, 
        "Insufficient capacity for #{product_variant.display_name} on #{bake_day.display_name}. " \
        "Requested: #{quantity}, Available: #{available_capacity}"
    end
    
    true
  end

  # Release capacity when order is cancelled or modified
  def release!(quantity)
    validate_quantity!(quantity)
    
    return true unless capacity_configured?
    return true unless production_cap.persisted?
    
    production_cap.release!(quantity)
  end

  # Validate order items capacity before order confirmation
  def self.validate_order_items!(order_items, bake_day)
    errors = []
    
    ActiveRecord::Base.transaction do
      order_items.each do |item|
        manager = new(item.product_variant, bake_day)
        
        unless manager.available?(item.quantity)
          errors << {
            variant: item.product_variant.display_name,
            requested: item.quantity,
            available: manager.available_capacity
          }
        end
      end
    end
    
    if errors.any?
      error_messages = errors.map do |e|
        "#{e[:variant]}: demandé #{e[:requested]}, disponible #{e[:available]}"
      end
      raise InsufficientCapacityError, "Capacité insuffisante:\n#{error_messages.join("\n")}"
    end
    
    true
  end

  # Bulk allocate capacity for multiple order items
  # Uses database transaction with row-level locking to ensure atomicity
  # All allocations succeed or none do (rollback on failure)
  #
  # @param order_items [Array] Array of order items to allocate
  # @param bake_day [BakeDay] The bake day for which to allocate capacity
  # @return [Boolean] true if all allocations succeed
  # @raise [InsufficientCapacityError] if any allocation fails
  # @raise [ActiveRecord::LockWaitTimeout] if locks cannot be acquired
  def self.allocate_order_items!(order_items, bake_day)
    allocated = []
    
    begin
      ActiveRecord::Base.transaction do
        order_items.each do |item|
          manager = new(item.product_variant, bake_day)
          manager.allocate!(item.quantity, use_retry: true)
          allocated << { manager: manager, quantity: item.quantity }
        end
      end
      true
    rescue StandardError => e
      # Transaction will auto-rollback on any error
      Rails.logger.error("Failed to allocate capacity: #{e.message}")
      raise e
    end
  end

  # Bulk release capacity for multiple order items
  def self.release_order_items!(order_items, bake_day)
    order_items.each do |item|
      manager = new(item.product_variant, bake_day)
      manager.release!(item.quantity)
    end
    true
  end

  # Get capacity status for display
  def status
    {
      configured: capacity_configured?,
      capacity: capacity_configured? ? production_cap.capacity : nil,
      reserved: capacity_configured? ? production_cap.reserved : 0,
      available: available_capacity == Float::INFINITY ? "unlimited" : available_capacity,
      percentage_reserved: capacity_configured? ? production_cap.percentage_reserved : 0
    }
  end

  # Get user-friendly status message
  def status_message
    return "Quantité illimitée" unless capacity_configured?
    
    remaining = available_capacity
    percentage = production_cap.percentage_reserved
    
    case percentage
    when 0...50
      "#{remaining} disponibles"
    when 50...80
      "Plus que #{remaining} disponibles"
    when 80...100
      "Dernières unités ! (#{remaining})"
    else
      "Épuisé"
    end
  end

  # Check if variant should be disabled in UI
  def should_disable?
    capacity_configured? && !available?(1)
  end

  private

  def validate_quantity!(quantity)
    if quantity <= 0
      raise InvalidQuantityError, "Quantity must be greater than 0"
    end
  end
end

