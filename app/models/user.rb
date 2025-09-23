class User < ApplicationRecord
  include Discard::Model
  extend FriendlyId
  friendly_id :user_name, use: [ :slugged, :history ]
  attr_accessor :remember_token, :reset_token
  has_one_attached :profile_picture
  has_secure_password
  enum :role, { member: 0, editor: 1, admin: 2 }
  before_validation :reject_if_banned, on: :create
  validates :name, presence: true
  validates :user_name, presence: true, uniqueness: { case_sensitive: false },
            format: { with: /\A[a-z0-9_]+\z/, message: "only allows letters, numbers, and underscores" },
            length: { minimum: 3 }

  validates :bio, allow_blank: true, length: { maximum: 500 }
  validates :email, presence: true, uniqueness: { case_sensitive: false },format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }
  validate :password_complexity, if: -> { new_record? || !password.nil? }


  has_many :articles, dependent: :destroy
  has_many :claps, dependent: :destroy
  has_many :clapped_articles, through: :claps, source: :article
  has_many :comments, dependent: :destroy
  has_many :reports, dependent: :destroy
  has_many :moderation_actions, class_name: "ModerationRecord", foreign_key: "admin_id", dependent: :nullify
  after_discard do
    articles.find_each(&:discard)
    comments.find_each(&:discard)
  end
  after_undiscard do
    articles.find_each(&:undiscard)
    comments.find_each(&:undiscard)
  end
  def self.new_token
    SecureRandom.urlsafe_base64(32)
  end

  def self.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  def remember
    self.remember_token = User.new_token
    #fixxxxx
    update_attribute(:remember_digest, User.digest(remember_token))
    update_attribute(:remember_expires_at, 30.days.from_now)
  end

  def create_reset_digest
    self.reset_token = User.new_token
    update_attribute(:reset_digest, User.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end

  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end
  def forget
    update_attribute(:remember_digest, nil)
    update_attribute(:remember_expires_at, nil)
    # update_attribute(:session_token,nil)
  end

  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  def regenerate_session_token
    update_attribute(:session_token, User.new_token)
  end

  def should_generate_new_friendly_id?
    user_name_changed? || super
  end


  private

  def password_complexity
    return if password.blank?
    unless password.match?(/[a-z]/)
      errors.add :password, "must include at least one lowercase letter"
    end
    unless password.match?(/[A-Z]/)
      errors.add :password, "must include at least one uppercase letter"
    end
    unless password.match?(/\d/)
      errors.add :password, "must include at least one digit"
    end
    unless password.match?(/[^A-Za-z\d]/)
      errors.add :password, "must include at least one special character i.e. (*, #, $ etc)"
    end
  end
  def reject_if_banned
    if User.discarded.exists?(email: email) || User.discarded.exists?(user_name: user_name)
      errors.add(:base, "This account is banned. Please use another email/username.")
      throw(:abort)
    end
  end
end
