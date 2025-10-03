class AdminPage < ApplicationRecord
  # Validations
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, 
            format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, 
                      message: "only allows lowercase letters, numbers, and hyphens" }
  validates :locale, presence: true, inclusion: { in: %w[fr nl en] }
  validates :published, inclusion: { in: [true, false] }

  # Callbacks
  before_validation :generate_slug, on: :create

  # Scopes
  scope :published, -> { where(published: true) }
  scope :draft, -> { where(published: false) }
  scope :in_locale, ->(locale) { where(locale: locale) }
  scope :for_locale, ->(locale) { published.in_locale(locale) }

  # Instance methods
  def publish!
    update!(published: true)
  end

  def unpublish!
    update!(published: false)
  end

  def draft?
    !published?
  end

  private

  def generate_slug
    return if slug.present?
    return unless title.present?
    
    # Generate slug from title
    base_slug = title.parameterize
    candidate_slug = base_slug
    counter = 1
    
    # Ensure uniqueness
    while AdminPage.exists?(slug: candidate_slug)
      candidate_slug = "#{base_slug}-#{counter}"
      counter += 1
    end
    
    self.slug = candidate_slug
  end
end
