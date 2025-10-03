module Admin
  class BakeDaysController < BaseController
    before_action :set_bake_day, only: [:show, :edit, :update, :destroy, :lock, :unlock, :complete]

    def index
      @bake_days = BakeDay.order(baked_on: :desc).page(params[:page]).per(20)
    end

    def show
      @production_caps = @bake_day.production_caps.includes(:product_variant)
      @orders = @bake_day.orders.includes(:customer, :order_items)
    end

    def new
      @bake_day = BakeDay.new
    end

    def create
      @bake_day = BakeDay.new(bake_day_params)
      
      if @bake_day.save
        redirect_to admin_bake_day_path(@bake_day), notice: "Date de cuisson créée avec succès."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @bake_day.update(bake_day_params)
        redirect_to admin_bake_day_path(@bake_day), notice: "Date de cuisson mise à jour."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @bake_day.orders.any?
        redirect_to admin_bake_day_path(@bake_day), alert: "Impossible de supprimer une date avec des commandes."
      else
        @bake_day.destroy
        redirect_to admin_bake_days_path, notice: "Date de cuisson supprimée."
      end
    end

    # Lock a bake day manually
    def lock
      if @bake_day.lock!
        redirect_to admin_bake_day_path(@bake_day), notice: "Date de cuisson verrouillée."
      else
        redirect_to admin_bake_day_path(@bake_day), alert: "Erreur lors du verrouillage."
      end
    end

    # Unlock a bake day (override)
    def unlock
      if @bake_day.update(status: "open")
        redirect_to admin_bake_day_path(@bake_day), notice: "Date de cuisson déverrouillée."
      else
        redirect_to admin_bake_day_path(@bake_day), alert: "Erreur lors du déverrouillage."
      end
    end

    # Mark a bake day as completed
    def complete
      if @bake_day.complete!
        redirect_to admin_bake_day_path(@bake_day), notice: "Date de cuisson marquée comme terminée."
      else
        redirect_to admin_bake_day_path(@bake_day), alert: "Erreur lors de la finalisation."
      end
    end

    private

    def set_bake_day
      @bake_day = BakeDay.find(params[:id])
    end

    def bake_day_params
      params.require(:bake_day).permit(:baked_on, :cut_off_at, :status)
    end
  end
end

