# Base class for all ActiveRecord models in the application.
# Provides common behavior and configuration shared across all models.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
