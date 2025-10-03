class BakeDay < ApplicationRecord
  # Associations
  has_many :production_caps, dependent: :destroy
  has_many :product_variants, through: :production_caps
  has_many :orders, dependent: :restrict_with_error

  # Validations
  validates :baked_on, presence: true, uniqueness: true
  validates :day_of_week, presence: true, inclusion: { in: 0..6 }
  validates :cut_off_at, presence: true
  validates :status, presence: true, inclusion: { in: %w[open locked completed] }

  # Callbacks
  before_validation :set_day_of_week, :calculate_cut_off, on: :create
  after_create :schedule_automatic_locking

  # Scopes
  scope :open, -> { where(status: "open") }
  scope :locked, -> { where(status: "locked") }
  scope :completed, -> { where(status: "completed") }
  scope :upcoming, -> { where("baked_on >= ?", Date.current).order(:baked_on) }
  scope :past, -> { where("baked_on < ?", Date.current).order(baked_on: :desc) }
  scope :for_day_of_week, ->(day) { where(day_of_week: day) }

  # Class methods
  def self.create_for_date(date)
    create!(baked_on: date)
  end

  def self.next_tuesday
    date = Date.current.next_occurring(:tuesday)
    find_or_create_by(baked_on: date)
  end

  def self.next_friday
    date = Date.current.next_occurring(:friday)
    find_or_create_by(baked_on: date)
  end

  # Instance methods
  def past_cut_off?
    Time.current > cut_off_at
  end

  def can_order?
    status == "open" && !past_cut_off?
  end

  def lock!
    update!(status: "locked")
  end

  def complete!
    update!(status: "completed")
  end

  def tuesday?
    day_of_week == 2
  end

  def friday?
    day_of_week == 5
  end

  def display_name
    baked_on.strftime("%A, %B %-d, %Y")
  end

  def time_remaining_until_cut_off
    return 0 if past_cut_off?
    
    (cut_off_at - Time.current).to_i
  end

  def formatted_time_remaining
    return "Fermé" if past_cut_off?
    
    seconds = time_remaining_until_cut_off
    days = seconds / 86400
    hours = (seconds % 86400) / 3600
    minutes = (seconds % 3600) / 60
    
    if days > 0
      "#{days}j #{hours}h"
    elsif hours > 0
      "#{hours}h #{minutes}min"
    else
      "#{minutes}min"
    end
  end

  def cut_off_display
    cut_off_at.in_time_zone("Europe/Brussels").strftime("%A %-d %B à %H:%M")
  end

  private

  def schedule_automatic_locking
    return if past_cut_off?
    OrderLockingJob.schedule_for(self)
  end

  def set_day_of_week
    return unless baked_on.present?
    self.day_of_week = baked_on.wday
  end

  def calculate_cut_off
    return unless baked_on.present?
    return if cut_off_at.present?

    # PRD: Sunday 18:00 for Tuesday, Wednesday 18:00 for Friday
    cut_off_date = case day_of_week
    when 2 # Tuesday
      baked_on - 2.days # Sunday
    when 5 # Friday
      baked_on - 2.days # Wednesday
    else
      baked_on - 1.day # Default: day before
    end

    # Set cut-off at 18:00 in Europe/Brussels timezone
    self.cut_off_at = Time.use_zone("Europe/Brussels") do
      cut_off_date.to_time.change(hour: 18, min: 0, sec: 0)
    end
  end
end
