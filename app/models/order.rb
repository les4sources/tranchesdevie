class Order < ApplicationRecord
  # Associations
  belongs_to :customer
  belongs_to :bake_day
  has_many :order_items, dependent: :destroy
  has_one :payment, dependent: :destroy

  # Enums
  enum :status, {
    pending: "pending",
    confirmed: "confirmed",
    ready: "ready",
    picked_up: "picked_up",
    no_show: "no_show",
    cancelled: "cancelled",
    refunded: "refunded"
  }, prefix: true

  # Validations
  validates :order_number, presence: true, uniqueness: true
  validates :total_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true

  # Callbacks
  before_validation :generate_order_number, on: :create
  before_save :calculate_total

  # Delegations
  delegate :baked_on, :display_name, to: :bake_day, prefix: :bake_day
  delegate :first_name, :last_name, :phone_e164, to: :customer, prefix: :customer

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_bake_day, ->(bake_day) { where(bake_day: bake_day) }
  scope :for_customer, ->(customer) { where(customer: customer) }

  # Instance methods
  def total_euros
    total_cents / 100.0
  end

  def total_euros=(value)
    self.total_cents = (value.to_f * 100).round
  end

  def mark_ready!
    update!(status: :ready, ready_at: Time.current)
  end

  def mark_picked_up!
    update!(status: :picked_up, picked_up_at: Time.current)
  end

  def mark_no_show!
    update!(status: :no_show)
  end

  def cancel!
    transaction do
      # Release production capacity
      order_items.each do |item|
        cap = ProductionCap.find_by(
          bake_day: bake_day,
          product_variant: item.product_variant
        )
        cap&.release!(item.quantity)
      end
      
      update!(status: :cancelled)
    end
  end

  def customer_name
    "#{customer_first_name} #{customer_last_name}".strip
  end

  def calculate_total
    self.total_cents = order_items.sum { |item| item.quantity * item.unit_price_cents }
  end

  private

  def generate_order_number
    return if order_number.present?
    
    # Format: YYYYMMDD-NNNN (e.g., 20251007-0001)
    date_prefix = Time.current.strftime("%Y%m%d")
    last_order = Order.where("order_number LIKE ?", "#{date_prefix}-%").order(:order_number).last
    
    if last_order
      last_number = last_order.order_number.split("-").last.to_i
      next_number = last_number + 1
    else
      next_number = 1
    end
    
    self.order_number = "#{date_prefix}-#{next_number.to_s.rjust(4, '0')}"
  end
end
