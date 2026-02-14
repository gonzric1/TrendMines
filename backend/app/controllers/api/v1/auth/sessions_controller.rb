# frozen_string_literal: true

module Api
  module V1
    # Authentication namespace for user session and registration endpoints.
    module Auth
      # Handles user session management (sign in/sign out).
      # Extends Devise's SessionsController to return JSON responses
      # with JWT tokens for API authentication.
      #
      # @example Sign in
      #   POST /api/v1/auth/sign_in
      #   { "user": { "email": "user@example.com", "password": "secret" } }
      #
      # @example Sign out
      #   DELETE /api/v1/auth/sign_out
      #   Authorization: Bearer <jwt-token>
      class SessionsController < Devise::SessionsController
        respond_to :json

        private

        # Renders user data as JSON on successful sign-in.
        # The JWT token is automatically set in the Authorization header by devise-jwt.
        #
        # @param resource [User] The authenticated user
        # @param _opts [Hash] Additional options (unused)
        # @return [void]
        def respond_with(resource, _opts = {})
          render json: {
            message: "Signed in successfully",
            user: {
              id: resource.id,
              email: resource.email,
              name: resource.name,
              role: resource.role
            }
          }, status: :ok
        end

        # Renders 401 Unauthorized when sign-in credentials are invalid.
        #
        # @param _resource [User] The unauthenticated user (unused)
        # @param _opts [Hash] Additional options (unused)
        # @return [void]
        def respond_with_failure(_resource, _opts = {})
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end

        # Responds with 204 No Content on sign-out.
        # The JWT token is automatically added to {JwtDenylist} by devise-jwt.
        #
        # @return [void]
        def respond_to_on_destroy
          head :no_content
        end
      end
    end
  end
end
