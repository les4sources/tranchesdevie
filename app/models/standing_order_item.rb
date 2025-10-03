class StandingOrderItem < ApplicationRecord
  # Associations
  belongs_to :standing_order
  belongs_to :product_variant

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :product_variant_id, uniqueness: { scope: :standing_order_id }

  # Delegations
  delegate :name, :display_name, :price_cents, :price_euros, to: :product_variant, prefix: :variant

  # Instance methods
  def subtotal_cents
    quantity * product_variant.price_cents
  end

  def subtotal_euros
    subtotal_cents / 100.0
  end
end
