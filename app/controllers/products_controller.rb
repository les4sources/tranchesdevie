class ProductsController < ApplicationController
  def index
    @products = Product.active
                      .includes(product_variants: [:product_availabilities, :production_caps])
                      .order(:category, :name)
    
    # Optional: Filter by bake day if provided
    if params[:bake_day_id].present?
      @selected_bake_day = BakeDay.find_by(id: params[:bake_day_id])
    end
    
    # Upcoming bake days for the selector
    @upcoming_bake_days = BakeDay.upcoming.open.limit(10)
  end

  def show
    @product = Product.active
                     .includes(product_variants: [:product_availabilities, :production_caps])
                     .find(params[:id])
    
    @upcoming_bake_days = BakeDay.upcoming.open.limit(10)
  end
end
