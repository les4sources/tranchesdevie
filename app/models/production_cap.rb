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

  # Reserve units with row-level locking to prevent race conditions
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
  end

  # Release reserved units
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
  end

  private

  def reserved_not_greater_than_capacity
    return if reserved.nil? || capacity.nil?
    
    if reserved > capacity
      errors.add(:reserved, "cannot be greater than capacity")
    end
  end
end
