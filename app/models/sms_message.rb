class SmsMessage < ApplicationRecord
  # Associations
  belongs_to :customer, optional: true

  # Enums
  enum :direction, {
    outbound: "outbound",
    inbound: "inbound"
  }, prefix: true

  enum :status, {
    pending: "pending",
    sent: "sent",
    delivered: "delivered",
    failed: "failed"
  }, prefix: true

  # Validations
  validates :phone_e164, presence: true
  validates :message_body, presence: true
  validates :direction, presence: true
  validates :status, presence: true
  validate :phone_number_must_be_valid

  # Callbacks
  before_validation :normalize_phone_number

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_phone, ->(phone) { where(phone_e164: phone) }
  scope :today, -> { where("created_at >= ?", Time.current.beginning_of_day) }

  # Class methods
  def self.send_message(phone:, message:, customer: nil)
    create!(
      phone_e164: phone,
      message_body: message,
      direction: :outbound,
      customer: customer
    )
  end

  def self.receive_message(phone:, message:, telerivet_id: nil)
    create!(
      phone_e164: phone,
      message_body: message,
      direction: :inbound,
      telerivet_message_id: telerivet_id,
      status: :delivered
    )
  end

  # Instance methods
  def mark_sent!(telerivet_id = nil)
    update!(
      status: :sent,
      sent_at: Time.current,
      telerivet_message_id: telerivet_id
    )
  end

  def mark_delivered!
    update!(status: :delivered)
  end

  def mark_failed!(error_msg)
    update!(
      status: :failed,
      error_message: error_msg
    )
  end

  def contains_pause_keyword?
    return false unless direction_inbound?
    message_body&.upcase&.include?("PAUSE")
  end

  def contains_stop_keyword?
    return false unless direction_inbound?
    message_body&.upcase&.include?("STOP")
  end

  private

  def normalize_phone_number
    return if phone_e164.blank?
    
    phone = if phone_e164.start_with?('+')
      Phonelib.parse(phone_e164)
    else
      Phonelib.parse(phone_e164, 'BE')
    end
    
    self.phone_e164 = phone.e164.presence
  end

  def phone_number_must_be_valid
    return if phone_e164.blank?
    
    phone = Phonelib.parse(phone_e164)
    unless phone.valid?
      errors.add(:phone_e164, "must be a valid phone number in E.164 format")
    end
  end
end
