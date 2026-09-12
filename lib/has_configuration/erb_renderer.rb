# frozen_string_literal: true

require "erb"

module HasConfiguration
  module ERBRenderer
    def self.render(source, file)
      template = ERB.new(source)
      template.filename = file.to_s
      template.result
    end
  end
end
