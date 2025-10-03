module ProductsHelper
  def variant_available_on_bake_day?(variant, bake_day)
    return true if bake_day.nil?
    variant.available_on?(bake_day.baked_on)
  end

  def variant_has_capacity?(variant, bake_day)
    return true if bake_day.nil?
    
    cap = variant.production_caps.find_by(bake_day: bake_day)
    cap.nil? || cap.available?
  end

  def variant_capacity_percentage(variant, bake_day)
    return 0 if bake_day.nil?
    
    cap = variant.production_caps.find_by(bake_day: bake_day)
    cap&.percentage_reserved || 0
  end

  def variant_remaining_capacity(variant, bake_day)
    return nil if bake_day.nil?
    
    cap = variant.production_caps.find_by(bake_day: bake_day)
    cap&.available
  end

  def variant_orderable?(variant, bake_day)
    available = variant_available_on_bake_day?(variant, bake_day)
    has_capacity = variant_has_capacity?(variant, bake_day)
    available && has_capacity
  end

  def capacity_status_class(percentage)
    case percentage
    when 0...50
      "text-green-600"
    when 50...80
      "text-orange-600"
    else
      "text-red-600"
    end
  end

  def capacity_status_text(variant, bake_day)
    return nil if bake_day.nil?
    
    remaining = variant_remaining_capacity(variant, bake_day)
    return "Capacité non définie" if remaining.nil?
    
    if remaining > 10
      "#{remaining} disponibles"
    elsif remaining > 0
      "Plus que #{remaining} !"
    else
      "Épuisé"
    end
  end
end
