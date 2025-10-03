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

  # Instance methods
  def available_variants
    product_variants.active
  end

  def has_variants?
    product_variants.any?
  end
end
