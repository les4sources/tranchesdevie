module Admin
  class DashboardController < BaseController
    def index
      @upcoming_bake_days = BakeDay.upcoming.limit(10)
      @open_bake_days = BakeDay.open.upcoming
      @locked_bake_days = BakeDay.locked.upcoming.limit(5)
      
      # Get capacity statistics
      @total_production_caps = ProductionCap.for_upcoming_bakes.count
      @caps_at_capacity = ProductionCap.for_upcoming_bakes.at_capacity.count
      @caps_with_capacity = ProductionCap.for_upcoming_bakes.with_capacity.count
      
      # Get recent orders
      @recent_orders = Order.recent.limit(10).includes(:customer, :bake_day)
    end
  end
end

