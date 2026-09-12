# frozen_string_literal: true

require "has_configuration/configuration"

module HasConfiguration
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # Loads a trusted YAML file once and installs class and instance getters.
    # Defaults to <class name downcased>.yml, or config/<name>.yml under Rails.root.
    # A loaded Rails supplies Rails.env; pass env: nil to read the complete file.
    # ERB is loaded only when the file contains ERB markup.
    # A subclass inherits its parent's immutable configuration unless it declares
    # its own, which replaces the inherited settings without merging.
    def has_configuration(options = {})
      @configuration = HasConfiguration::Configuration.new(self, options)
      include Getter
    end

    module Getter
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def configuration
          return @configuration if instance_variable_defined?(:@configuration)
          superclass.configuration if respond_to?(:superclass) && superclass.respond_to?(:configuration)
        end
      end

      def configuration
        self.class.configuration
      end
    end
  end
end

class Object
  include HasConfiguration
end
