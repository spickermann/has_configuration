# frozen_string_literal: true

require "active_support/core_ext/hash/indifferent_access"

module HasConfiguration
  module IndifferentAccess
    def self.convert(hash)
      hash.with_indifferent_access
    end
  end
end
