class OrderItem < ApplicationRecord
  # Associations
  belongs_to :order
  belongs_to :product_variant

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :unit_price_cents, presence: true, numericality: { greater_than: 0 }
  validates :product_variant_id, uniqueness: { scope: :order_id }

  # Callbacks
  before_validation :set_unit_price, on: :create
  after_save :update_order_total
  after_destroy :update_order_total

  # Delegations
  delegate :name, :display_name, to: :product_variant, prefix: :variant

  # Instance methods
  def subtotal_cents
    quantity * unit_price_cents
  end

  def subtotal_euros
    subtotal_cents / 100.0
  end

  def unit_price_euros
    unit_price_cents / 100.0
  end

  def unit_price_euros=(value)
    self.unit_price_cents = (value.to_f * 100).round
  end

  private

  def set_unit_price
    return if unit_price_cents.present?
    self.unit_price_cents = product_variant.price_cents
  end

  def update_order_total
    order.calculate_total
    order.save if order.persisted?
  end
end
