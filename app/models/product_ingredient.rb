class ProductIngredient < ApplicationRecord
  # Associations
  belongs_to :product
  belongs_to :ingredient

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :ingredient_id, uniqueness: { scope: :product_id, 
                                          message: "already added to this product" }

  # Delegations
  delegate :name, :is_allergen?, :allergen_type, to: :ingredient, prefix: true

  # Instance methods
  def display_quantity
    return "#{quantity} #{unit}" if unit.present?
    "#{quantity} #{ingredient.unit}"
  end

  def effective_unit
    unit.presence || ingredient.unit
  end

  # Calculate total quantity needed for a given number of products
  def total_for(product_count)
    quantity * product_count
  end
end
