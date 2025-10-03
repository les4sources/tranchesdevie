# Service for checking and displaying production capacity status
class CapacityChecker
  attr_reader :variant, :bake_day

  def initialize(variant, bake_day)
    @variant = variant
    @bake_day = bake_day
  end

  def production_cap
    @production_cap ||= variant.production_caps.find_by(bake_day: bake_day) if bake_day.present?
  end

  def has_capacity_limit?
    production_cap.present?
  end

  def available?
    return true unless has_capacity_limit?
    production_cap.available?
  end

  def remaining
    return nil unless has_capacity_limit?
    production_cap.available
  end

  def percentage_reserved
    return 0 unless has_capacity_limit?
    production_cap.percentage_reserved
  end

  def status_level
    case percentage_reserved
    when 0...50
      :plenty
    when 50...80
      :limited
    when 80...100
      :very_limited
    else
      :sold_out
    end
  end

  def status_badge_class
    case status_level
    when :plenty
      "bg-green-100 text-green-800"
    when :limited
      "bg-orange-100 text-orange-800"
    when :very_limited
      "bg-red-100 text-red-800 animate-pulse"
    when :sold_out
      "bg-gray-100 text-gray-800"
    end
  end

  def status_text_class
    case status_level
    when :plenty
      "text-green-600"
    when :limited
      "text-orange-600"
    when :very_limited
      "text-red-600 font-semibold"
    when :sold_out
      "text-gray-600"
    end
  end

  def status_message
    return nil unless has_capacity_limit?
    
    case status_level
    when :plenty
      "#{remaining} disponibles"
    when :limited
      "Plus que #{remaining} disponibles"
    when :very_limited
      "Dernières unités ! (#{remaining})"
    when :sold_out
      "Épuisé"
    end
  end

  def show_progress_bar?
    has_capacity_limit? && percentage_reserved > 0
  end

  def progress_bar_class
    case status_level
    when :plenty
      "bg-green-500"
    when :limited
      "bg-orange-500"
    when :very_limited, :sold_out
      "bg-red-500"
    end
  end
end
