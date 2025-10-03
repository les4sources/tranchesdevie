# Job to automatically lock bake days at their cut-off time
# Prevents further ordering after the deadline has passed
class OrderLockingJob < ApplicationJob
  queue_as :default

  # Retry configuration for handling transient failures
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # Perform the locking operation for a specific bake day
  # @param bake_day_id [Integer] The ID of the bake day to lock
  def perform(bake_day_id)
    bake_day = BakeDay.find(bake_day_id)
    
    # Verify that cut-off has actually passed (safety check)
    unless bake_day.past_cut_off?
      Rails.logger.warn("OrderLockingJob called for bake day #{bake_day_id} but cut-off hasn't passed yet")
      return
    end

    # Skip if already locked or completed
    if bake_day.status != "open"
      Rails.logger.info("OrderLockingJob: Bake day #{bake_day_id} is already #{bake_day.status}")
      return
    end

    # Lock the bake day within a transaction
    ActiveRecord::Base.transaction do
      bake_day.lock!
      Rails.logger.info("OrderLockingJob: Successfully locked bake day #{bake_day_id} (#{bake_day.display_name})")
    end

  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("OrderLockingJob: Bake day #{bake_day_id} not found - #{e.message}")
    # Don't retry if record doesn't exist
  rescue StandardError => e
    Rails.logger.error("OrderLockingJob: Failed to lock bake day #{bake_day_id} - #{e.message}")
    raise # Will trigger retry logic
  end

  # Schedule locking job for a bake day at its cut-off time
  # @param bake_day [BakeDay] The bake day to schedule locking for
  def self.schedule_for(bake_day)
    return unless bake_day.present?
    return if bake_day.past_cut_off?

    # Schedule the job to run at the cut-off time
    set(wait_until: bake_day.cut_off_at).perform_later(bake_day.id)
    
    Rails.logger.info("OrderLockingJob: Scheduled for bake day #{bake_day.id} at #{bake_day.cut_off_at}")
  end

  # Schedule locking jobs for all upcoming open bake days
  def self.schedule_all_upcoming
    count = 0
    
    BakeDay.open.upcoming.each do |bake_day|
      next if bake_day.past_cut_off?
      
      schedule_for(bake_day)
      count += 1
    end
    
    Rails.logger.info("OrderLockingJob: Scheduled #{count} locking jobs")
    count
  end

  # Lock all bake days whose cut-off has passed (for manual/recovery use)
  def self.lock_overdue_bake_days
    count = 0
    
    BakeDay.open.where("cut_off_at <= ?", Time.current).find_each do |bake_day|
      begin
        bake_day.lock!
        count += 1
        Rails.logger.info("OrderLockingJob: Manually locked overdue bake day #{bake_day.id}")
      rescue StandardError => e
        Rails.logger.error("OrderLockingJob: Failed to lock overdue bake day #{bake_day.id} - #{e.message}")
      end
    end
    
    Rails.logger.info("OrderLockingJob: Manually locked #{count} overdue bake days")
    count
  end
end
