# Represents an authenticated user of the TrendMines dashboard.
# Users sign in with email/password and receive JWT tokens for API access.
# Supports role-based authorization (operator vs admin).
#
# @attr [Integer] id Primary key
# @attr [String] email User's email address (unique, used for login)
# @attr [String] encrypted_password Bcrypt-hashed password
# @attr [String] name User's display name
# @attr [Integer] role Role enum (0=operator, 1=admin)
# @attr [String] reset_password_token Token for password reset flow
# @attr [DateTime] reset_password_sent_at When the reset token was issued
# @attr [DateTime] remember_created_at When "remember me" was activated
# @attr [DateTime] created_at Record creation timestamp
# @attr [DateTime] updated_at Record update timestamp
class User < ApplicationRecord
  # Devise modules for authentication, registration, password recovery,
  # session persistence, and JWT token-based API authentication.
  # @note JWT revocation uses {JwtDenylist} denylist strategy
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # User authorization role
  # @note Default role is :operator
  enum :role, { operator: 0, admin: 1 }

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :role, presence: true
end
