module Admin
  class ProductionCapsController < BaseController
    before_action :set_bake_day
    before_action :set_production_cap, only: [:edit, :update, :destroy]

    def index
      @production_caps = @bake_day.production_caps.includes(:product_variant).order("product_variants.name")
      @available_variants = ProductVariant.active.where.not(id: @production_caps.pluck(:product_variant_id))
    end

    def new
      @production_cap = @bake_day.production_caps.build
      @available_variants = ProductVariant.active.where.not(
        id: @bake_day.production_caps.pluck(:product_variant_id)
      )
    end

    def create
      @production_cap = @bake_day.production_caps.build(production_cap_params)
      
      if @production_cap.save
        redirect_to admin_bake_day_production_caps_path(@bake_day), 
                    notice: "Capacité de production ajoutée."
      else
        @available_variants = ProductVariant.active.where.not(
          id: @bake_day.production_caps.pluck(:product_variant_id)
        )
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @production_cap.update(production_cap_params)
        redirect_to admin_bake_day_production_caps_path(@bake_day), 
                    notice: "Capacité de production mise à jour."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @production_cap.reserved > 0
        redirect_to admin_bake_day_production_caps_path(@bake_day), 
                    alert: "Impossible de supprimer une capacité avec des réservations."
      else
        @production_cap.destroy
        redirect_to admin_bake_day_production_caps_path(@bake_day), 
                    notice: "Capacité de production supprimée."
      end
    end

    # Bulk update capacities for all variants on this bake day
    def bulk_update
      success_count = 0
      errors = []

      params[:production_caps]&.each do |id, cap_params|
        production_cap = @bake_day.production_caps.find_by(id: id)
        next unless production_cap
        
        if production_cap.update(capacity: cap_params[:capacity])
          success_count += 1
        else
          errors << "#{production_cap.product_variant_display_name}: #{production_cap.errors.full_messages.join(', ')}"
        end
      end

      if errors.empty?
        redirect_to admin_bake_day_production_caps_path(@bake_day), 
                    notice: "#{success_count} capacités mises à jour."
      else
        redirect_to admin_bake_day_production_caps_path(@bake_day), 
                    alert: "Erreurs: #{errors.join('; ')}"
      end
    end

    # Copy capacities from another bake day
    def copy_from
      source_bake_day = BakeDay.find(params[:source_bake_day_id])
      copied_count = 0

      source_bake_day.production_caps.each do |source_cap|
        existing = @bake_day.production_caps.find_by(product_variant_id: source_cap.product_variant_id)
        
        if existing
          existing.update(capacity: source_cap.capacity)
        else
          @bake_day.production_caps.create(
            product_variant_id: source_cap.product_variant_id,
            capacity: source_cap.capacity,
            reserved: 0
          )
        end
        copied_count += 1
      end

      redirect_to admin_bake_day_production_caps_path(@bake_day),
                  notice: "#{copied_count} capacités copiées depuis #{source_bake_day.display_name}."
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_bake_day_production_caps_path(@bake_day),
                  alert: "Date de cuisson source introuvable."
    end

    private

    def set_bake_day
      @bake_day = BakeDay.find(params[:bake_day_id])
    end

    def set_production_cap
      @production_cap = @bake_day.production_caps.find(params[:id])
    end

    def production_cap_params
      params.require(:production_cap).permit(:product_variant_id, :capacity)
    end
  end
end

