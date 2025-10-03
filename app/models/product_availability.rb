class ProductAvailability < ApplicationRecord
  # Associations
  belongs_to :product_variant

  # Validations
  validate :available_until_after_available_from
  validate :valid_days_of_week

  # Scopes
  scope :current, -> { where("available_from IS NULL OR available_from <= ?", Date.current)
                        .where("available_until IS NULL OR available_until >= ?", Date.current) }
  scope :upcoming, -> { where("available_from > ?", Date.current) }
  scope :expired, -> { where("available_until < ?", Date.current) }

  # Instance methods
  def active_on?(date)
    date_in_range = available_from.blank? || date >= available_from
    date_in_range &&= available_until.blank? || date <= available_until
    
    day_allowed = days_of_week.blank? || days_of_week.split(',').map(&:to_i).include?(date.wday)
    
    date_in_range && day_allowed
  end

  def day_names
    return "All days" if days_of_week.blank?
    
    days = days_of_week.split(',').map(&:to_i)
    day_map = { 0 => "Sunday", 1 => "Monday", 2 => "Tuesday", 3 => "Wednesday", 
                4 => "Thursday", 5 => "Friday", 6 => "Saturday" }
    days.map { |d| day_map[d] }.join(", ")
  end

  private

  def available_until_after_available_from
    return if available_from.blank? || available_until.blank?
    
    if available_until < available_from
      errors.add(:available_until, "must be after available_from")
    end
  end

  def valid_days_of_week
    return if days_of_week.blank?
    
    days = days_of_week.split(',').map(&:to_i)
    invalid_days = days.reject { |d| (0..6).include?(d) }
    
    if invalid_days.any?
      errors.add(:days_of_week, "contains invalid day numbers: #{invalid_days.join(', ')}")
    end
  end
end
