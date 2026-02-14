# frozen_string_literal: true

module Api
  module V1
    module Auth
      # Handles user registration via JSON API.
      # Extends Devise's RegistrationsController to accept and return JSON,
      # allowing new users to create accounts with name, email, and role.
      #
      # @example Register a new user
      #   POST /api/v1/auth
      #   { "user": { "email": "new@example.com", "password": "secret123",
      #               "password_confirmation": "secret123", "name": "Jane", "role": "operator" } }
      class RegistrationsController < Devise::RegistrationsController
        respond_to :json

        private

        # Renders user data as JSON after registration attempt.
        # Returns 201 Created on success or 422 Unprocessable Entity on validation failure.
        #
        # @param resource [User] The user being registered
        # @param _opts [Hash] Additional options (unused)
        # @return [void]
        def respond_with(resource, _opts = {})
          if resource.persisted?
            render json: {
              message: "User registered successfully",
              user: {
                id: resource.id,
                email: resource.email,
                name: resource.name,
                role: resource.role
              }
            }, status: :created
          else
            render json: {
              errors: resource.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # Strong parameters for user registration.
        # Permits email, password, password_confirmation, name, and role.
        #
        # @return [ActionController::Parameters] Permitted registration attributes
        def sign_up_params
          params.require(:user).permit(:email, :password, :password_confirmation, :name, :role)
        end
      end
    end
  end
end
