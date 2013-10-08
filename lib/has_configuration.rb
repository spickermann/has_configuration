module HasConfiguration

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def has_configuration(options = {})
      @configuration = Configuration.new(self, options)
      include Getter
    end

    module Getter

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def configuration
          @configuration
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
