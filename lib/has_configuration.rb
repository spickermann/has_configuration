# frozen_string_literal: true

require 'has_configuration/configuration'

module HasConfiguration # :nodoc:
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods # :nodoc:
    # Load configuration settings from a yaml file and adds a class and an instance
    # method +configuration+ to the object.
    #
    # ==== options
    #
    # [+file+]  The yml file to load:
    #           Defaults to <tt>config/classname.yml</tt> if Rails is defined,
    #           <tt>classname.yml</tt> otherwise.
    # [+env+]   The environment to load from the file.
    #           Defaults to +Rails.env+ if Rails is defined, no default if not.
    #
    # ==== Integration Examples
    #
    #   has_configuration
    #   # => loads setting without environment processing from the
    #   #    file #{self.class.name.downcase}.yml
    #
    #   has_configuration file: Rails.root.join('config', 'example.yml'), env: 'staging'
    #   # => loads settings for staging environment from RAILS_ROOT/config/example.yml file
    #
    # ==== YAML File Example
    #
    # The yaml file may contain defaults. Nesting is not limited. ERB in the yaml
    # file is evaluated.
    #
    #   defaults: &defaults
    #     user: root
    #     some:
    #       nested: value
    #
    #   development:
    #     <<: *defaults
    #     password: secret
    #
    #   production:
    #     <<: *defaults
    #     password: <%= ENV[:secret] &>
    #
    # ==== Configuration Retrieval
    #
    # If the example above was loaded into a class +Foo+ in +production+ environment:
    #
    #   Foo.configuration       # => <HasConfiguration::Configuration:0x00...>
    #   Foo.new.configuration   # => <HasConfiguration::Configuration:0x00...>
    #
    #   # convenient getter methods
    #   Foo.configuration.some.nested             # => "value"
    #
    #   # to_h returns a HashWithIndifferentAccess
    #   Foo.configuration.to_h                    # => { :user => "root",
    #                                             #      :password => "prod-secret",
    #                                             #      :some => { :nested => "value" } }
    #   Foo.configuration.to_h[:some][:nested]    # => "value"
    #   Foo.configuration.to_h[:some]['nested']   # => "value"
    #
    #   # force a special key type (when merging with other hashes)
    #   Foo.configuration.to_h(:symbolized)       # => { :user => "root",
    #                                             #      :password => "prod-secret",
    #                                             #      :some => { :nested => "value" } }
    #   Foo.configuration.to_h(:stringify)        # => { 'user' => "root",
    #                                             #      'password' => "prod-secret",
    #                                             #      'some' => { 'nested' => "value" } }
    #
    def has_configuration(options = {})
      @configuration = Configuration.new(self, options)
      include Getter
    end

    # Adds getters for the configuration
    module Getter
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods # :nodoc:
        attr_reader :configuration
      end

      def configuration
        self.class.configuration
      end
    end
  end
end

class Object # :nodoc:
  include HasConfiguration
end
