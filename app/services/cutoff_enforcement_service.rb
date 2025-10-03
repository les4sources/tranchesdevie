# Service class to enforce cut-off times for bake days
# Checks if ordering is allowed based on current time and cut-off deadlines
class CutoffEnforcementService
  class CutoffPassedError < StandardError; end

  def initialize(bake_day)
    @bake_day = bake_day
  end

  # Check if ordering is currently allowed for this bake day
  def ordering_allowed?
    return false unless @bake_day.present?
    return false if @bake_day.status != "open"
    
    !cut_off_passed?
  end

  # Check if the cut-off has passed for this bake day
  def cut_off_passed?
    current_time_in_brussels > @bake_day.cut_off_at
  end

  # Get the current time in Europe/Brussels timezone
  def current_time_in_brussels
    Time.current.in_time_zone("Europe/Brussels")
  end

  # Validate that ordering is allowed, raise error if not
  def validate_ordering!
    raise CutoffPassedError, cutoff_error_message unless ordering_allowed?
  end

  # Get user-friendly message about ordering status
  def ordering_status_message
    return "Les commandes sont fermées pour cette date" unless @bake_day.present?
    
    if @bake_day.status == "locked"
      "Les commandes sont verrouillées pour cette cuisson"
    elsif @bake_day.status == "completed"
      "Cette cuisson est terminée"
    elsif cut_off_passed?
      "La date limite de commande est dépassée (#{@bake_day.cut_off_display})"
    else
      "Commandes ouvertes jusqu'au #{@bake_day.cut_off_display}"
    end
  end

  # Check if UI elements should be disabled
  def should_disable_ordering?
    !ordering_allowed?
  end

  # Get CSS classes for UI state
  def ui_state_classes
    if should_disable_ordering?
      "opacity-50 cursor-not-allowed"
    else
      "cursor-pointer hover:shadow-lg"
    end
  end

  # Class method to check multiple bake days at once
  def self.available_bake_days
    BakeDay.open.upcoming.select do |bake_day|
      new(bake_day).ordering_allowed?
    end
  end

  # Class method to get next available bake day for ordering
  def self.next_available_bake_day
    available_bake_days.first
  end

  # Class method to check if a specific date is available for ordering
  def self.date_available_for_ordering?(date)
    bake_day = BakeDay.find_by(baked_on: date)
    return false unless bake_day
    
    new(bake_day).ordering_allowed?
  end

  private

  def cutoff_error_message
    if @bake_day.nil?
      "Aucune date de cuisson disponible"
    elsif @bake_day.status == "locked"
      "Les commandes sont verrouillées pour le #{@bake_day.display_name}"
    elsif @bake_day.status == "completed"
      "La cuisson du #{@bake_day.display_name} est déjà terminée"
    else
      "La date limite de commande pour le #{@bake_day.display_name} était le #{@bake_day.cut_off_display}"
    end
  end
end

