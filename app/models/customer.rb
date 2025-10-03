class Customer < ApplicationRecord
  # Associations
  has_many :phone_verifications, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :standing_orders, dependent: :destroy

  # Validations
  validates :first_name, presence: true
  validates :phone_e164, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  
  validate :phone_number_must_be_valid

  # Callbacks
  before_validation :normalize_phone_number

  # Scopes
  scope :verified, -> { where.not(verified_at: nil) }

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
end
