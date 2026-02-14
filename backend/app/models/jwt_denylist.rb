# Stores revoked JWT tokens to prevent reuse after sign-out.
# Used by devise-jwt as the denylist revocation strategy.
# When a user signs out, their JWT `jti` claim is added here
# so subsequent requests with that token are rejected.
#
# @attr [Integer] id Primary key
# @attr [String] jti JWT unique identifier (the revoked token's jti claim)
# @attr [DateTime] exp Token expiration timestamp (for cleanup of expired entries)
# @attr [DateTime] created_at Record creation timestamp
# @attr [DateTime] updated_at Record update timestamp
class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist

  self.table_name = "jwt_denylists"
end
