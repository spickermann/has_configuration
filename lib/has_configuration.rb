module HasConfiguration

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def has_configuration(options = {})

      class_eval <<-END_OF_RUBY, __FILE__, __LINE__ + 1

        def self.configuration
          @configuration ||= Configuration.new(self, #{options.inspect})
        end

        def configuration
          self.class.configuration
        end

      END_OF_RUBY

    end
  end

end

Object.class_eval { include HasConfiguration }
