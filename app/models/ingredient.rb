class Ingredient < ApplicationRecord
  # Associations
  has_many :product_ingredients, dependent: :destroy
  has_many :products, through: :product_ingredients

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :unit, presence: true
  validates :is_allergen, inclusion: { in: [true, false] }
  validates :allergen_type, presence: true, if: :is_allergen?

  # Scopes
  scope :allergens, -> { where(is_allergen: true) }
  scope :non_allergens, -> { where(is_allergen: false) }
  scope :by_type, ->(type) { where(allergen_type: type) }

  # Constants for common allergen types
  ALLERGEN_TYPES = %w[
    gluten
    dairy
    eggs
    nuts
    peanuts
    sesame
    soy
    fish
    shellfish
  ].freeze

  # Instance methods
  def allergen_label
    return nil unless is_allergen?
    allergen_type&.capitalize
  end
end
