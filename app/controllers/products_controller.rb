class ProductsController < ApplicationController
  def index
    # Get upcoming bake days for the selector
    @upcoming_bake_days = BakeDay.upcoming.open.limit(10)
    
    # Filter by selected bake day if provided
    if params[:bake_day_id].present?
      @selected_bake_day = BakeDay.find_by(id: params[:bake_day_id])
      
      if @selected_bake_day
        # Filter products available on the selected date
        @products = Product.active
                          .available_on_date(@selected_bake_day.baked_on)
                          .includes(product_variants: [:product_availabilities, :production_caps])
                          .order(:category, :name)
      else
        @products = Product.active
                          .includes(product_variants: [:product_availabilities, :production_caps])
                          .order(:category, :name)
      end
    else
      # Show all active products with available variants
      @products = Product.active
                        .with_available_variants
                        .includes(product_variants: [:product_availabilities, :production_caps])
                        .order(:category, :name)
    end
  end

  def show
    @product = Product.active
                     .includes(product_variants: [:product_availabilities, :production_caps])
                     .find(params[:id])
    
    @upcoming_bake_days = BakeDay.upcoming.open.limit(10)
    @selected_bake_day = BakeDay.find_by(id: params[:bake_day_id]) if params[:bake_day_id].present?
  end
end
