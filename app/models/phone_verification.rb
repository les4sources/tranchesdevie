class PhoneVerification < ApplicationRecord
  # Associations
  belongs_to :customer, optional: true

  # Validations
  validates :phone_e164, presence: true
  validates :verification_code, presence: true, length: { is: 6 }
  validates :expires_at, presence: true
  
  validate :phone_number_must_be_valid

  # Callbacks
  before_validation :normalize_phone_number, :generate_verification_code, on: :create
  before_validation :set_expiration, on: :create

  # Scopes
  scope :verified, -> { where.not(verified_at: nil) }
  scope :unverified, -> { where(verified_at: nil) }
  scope :active, -> { unverified.where("expires_at > ?", Time.current) }
  scope :expired, -> { unverified.where("expires_at <= ?", Time.current) }

  # Instance methods
  def verified?
    verified_at.present?
  end

  def expired?
    expires_at <= Time.current
  end

  def verify!(code)
    return false if expired?
    return false if verified?
    return false unless verification_code == code

    update!(verified_at: Time.current)
    true
  end

  private

  def normalize_phone_number
    return if phone_e164.blank?
    
    # Try parsing with Belgium country code if not already international
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

  def generate_verification_code
    self.verification_code ||= SecureRandom.random_number(100_000..999_999).to_s
  end

  def set_expiration
    self.expires_at ||= 15.minutes.from_now
  end
end
