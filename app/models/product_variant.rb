class ProductVariant < ApplicationRecord
  # Associations
  belongs_to :product
  has_many :product_availabilities, dependent: :destroy
  # TODO: Add these associations when models are created:
  # has_many :order_items, dependent: :restrict_with_error
  # has_many :production_caps, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: { scope: :product_id }
  validates :price_cents, presence: true, numericality: { greater_than: 0 }
  validates :weight_grams, numericality: { greater_than: 0, allow_nil: true }
  validates :active, inclusion: { in: [true, false] }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_weight, -> { order(:weight_grams) }

  # Instance methods
  def price_euros
    price_cents / 100.0
  end

  def price_euros=(value)
    self.price_cents = (value.to_f * 100).round
  end

  def display_name
    weight = weight_grams ? " (#{weight_grams}g)" : ""
    "#{product.name} - #{name}#{weight}"
  end

  def available_on?(date)
    return true if product_availabilities.empty?

    day_of_week = date.wday
    
    product_availabilities.any? do |availability|
      date_in_range = availability.available_from.blank? || date >= availability.available_from
      date_in_range &&= availability.available_until.blank? || date <= availability.available_until
      
      day_allowed = availability.days_of_week.blank? || 
                    availability.days_of_week.split(',').map(&:to_i).include?(day_of_week)
      
      date_in_range && day_allowed
    end
  end
end
