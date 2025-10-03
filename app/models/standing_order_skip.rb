class StandingOrderSkip < ApplicationRecord
  # Associations
  belongs_to :standing_order

  # Validations
  validates :skipped_date, presence: true
  validates :skipped_date, uniqueness: { scope: :standing_order_id }
  validates :reason, inclusion: { in: %w[pause stop manual], allow_nil: true }

  # Scopes
  scope :paused, -> { where(reason: "pause") }
  scope :stopped, -> { where(reason: "stop") }
  scope :future, -> { where("skipped_date >= ?", Date.current) }
  scope :past, -> { where("skipped_date < ?", Date.current) }

  # Instance methods
  def from_sms?
    reason.in?(%w[pause stop])
  end
end
