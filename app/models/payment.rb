class Payment < ApplicationRecord
  # Associations
  belongs_to :order

  # Enums
  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed",
    refunded: "refunded"
  }, prefix: true

  enum :payment_method, {
    card: "card",
    bancontact: "bancontact",
    apple_pay: "apple_pay",
    google_pay: "google_pay"
  }, prefix: true

  # Validations
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true
  validates :stripe_payment_intent_id, uniqueness: true, allow_nil: true
  validate :amount_matches_order_total

  # Callbacks
  after_create :update_order_status

  # Delegations
  delegate :order_number, :customer_name, to: :order, prefix: false

  # Instance methods
  def amount_euros
    amount_cents / 100.0
  end

  def amount_euros=(value)
    self.amount_cents = (value.to_f * 100).round
  end

  def mark_completed!
    update!(
      status: :completed,
      processed_at: Time.current
    )
  end

  def mark_failed!(error_msg = nil)
    update!(
      status: :failed,
      error_message: error_msg
    )
  end

  def refund!(refund_id)
    update!(
      status: :refunded,
      refund_id: refund_id,
      refunded_at: Time.current
    )
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def refunded?
    status == "refunded"
  end

  def pending?
    status == "pending"
  end

  private

  def amount_matches_order_total
    return unless order.present?
    
    if amount_cents != order.total_cents
      errors.add(:amount_cents, "must match order total (#{order.total_cents} cents)")
    end
  end

  def update_order_status
    return unless completed?
    order.update(status: :confirmed) if order.status_pending?
  end
end
