# Base controller for the Rails API application.
# Provides common behavior and configuration shared across all controllers.
class ApplicationController < ActionController::API
  # Include cookies/sessions support for devise-jwt
  include ActionController::Cookies
end
