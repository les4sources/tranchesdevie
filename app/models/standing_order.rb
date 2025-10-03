class StandingOrder < ApplicationRecord
  # Associations
  belongs_to :customer
  has_many :standing_order_items, dependent: :destroy
  has_many :product_variants, through: :standing_order_items
  has_many :standing_order_skips, dependent: :destroy

  # Enums
  enum :frequency, {
    tuesday: "tuesday",
    friday: "friday",
    both: "both"
  }, prefix: true

  enum :status, {
    active: "active",
    paused: "paused",
    cancelled: "cancelled"
  }, prefix: true

  # Validations
  validates :frequency, presence: true
  validates :status, presence: true

  # Delegations
  delegate :first_name, :last_name, :phone_e164, to: :customer, prefix: :customer

  # Scopes
  scope :for_tuesday, -> { where(frequency: [:tuesday, :both]) }
  scope :for_friday, -> { where(frequency: [:friday, :both]) }
  scope :needing_reminder, ->(days_ahead) {
    date = days_ahead.days.from_now.to_date
    active.where(next_bake_date: date)
  }

  # Instance methods
  def pause_delivery!(date, reason: "pause")
    standing_order_skips.create!(
      skipped_date: date,
      reason: reason
    )
  end

  def pause!
    update!(status: :paused)
  end

  def resume!
    update!(status: :active) if status_paused?
  end

  def cancel!
    update!(status: :cancelled)
  end

  def skipped?(date)
    standing_order_skips.exists?(skipped_date: date)
  end

  def should_deliver_on?(date)
    return false unless status_active?
    return false if skipped?(date)
    
    day_of_week = date.wday
    case frequency
    when "tuesday"
      day_of_week == 2
    when "friday"
      day_of_week == 5
    when "both"
      day_of_week.in?([2, 5])
    else
      false
    end
  end

  def update_next_bake_date!
    next_date = calculate_next_bake_date
    update!(next_bake_date: next_date)
  end

  def total_euros
    standing_order_items.sum { |item| item.quantity * item.product_variant.price_cents } / 100.0
  end

  def customer_name
    "#{customer_first_name} #{customer_last_name}".strip
  end

  private

  def calculate_next_bake_date
    today = Date.current
    
    case frequency
    when "tuesday"
      today.next_occurring(:tuesday)
    when "friday"
      today.next_occurring(:friday)
    when "both"
      # Next Tuesday or Friday, whichever comes first
      next_tuesday = today.next_occurring(:tuesday)
      next_friday = today.next_occurring(:friday)
      [next_tuesday, next_friday].min
    end
  end
end
