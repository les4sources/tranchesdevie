class Product < ApplicationRecord
  # Associations
  has_many :product_variants, dependent: :destroy
  has_many :product_ingredients, dependent: :destroy
  has_many :ingredients, through: :product_ingredients

  # Validations
  validates :name, presence: true
  validates :active, inclusion: { in: [true, false] }
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_category, ->(category) { where(category: category) }
  scope :available_on_date, ->(date) {
    joins(product_variants: :product_availabilities)
      .where("product_availabilities.available_from IS NULL OR product_availabilities.available_from <= ?", date)
      .where("product_availabilities.available_until IS NULL OR product_availabilities.available_until >= ?", date)
      .where("product_availabilities.days_of_week IS NULL OR product_availabilities.days_of_week LIKE ?", "%#{date.wday}%")
      .distinct
  }
  scope :with_available_variants, -> { 
    joins(:product_variants).where(product_variants: { active: true }).distinct 
  }

  # Instance methods
  def available_variants
    product_variants.active
  end

  def has_variants?
    product_variants.any?
  end
end
