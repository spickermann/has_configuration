# frozen_string_literal: true

module HasConfiguration
  # A deeply immutable configuration value with strict, read-only dot access.
  class Node
    def initialize(values)
      @values = values.to_h do |key, value|
        [key.dup.freeze, freeze_value(value)]
      end.freeze
      freeze
    end

    # Returns a detached, mutable snapshot, including nested strings and arrays.
    def to_h(type = nil)
      result = @values.to_h do |key, value|
        [(type == :symbolized) ? key.to_sym : key.dup, export_value(value, type)]
      end
      return result unless type == :indifferent

      begin
        require "active_support/core_ext/hash/indifferent_access"
      rescue LoadError
        raise LoadError, "to_h(:indifferent) requires the optional activesupport gem; add it to your Gemfile"
      end
      result.with_indifferent_access
    end

    # Avoid exposing configuration secrets in missing-method error messages.
    def inspect
      "#<#{self.class.name}>"
    end

    private

    def method_missing(name, *args, **kwargs, &block)
      return super unless @values.key?(name.to_s)
      unless args.empty? && kwargs.empty? && block.nil?
        raise ArgumentError, "configuration getters do not accept arguments or blocks"
      end

      @values.fetch(name.to_s)
    end

    def respond_to_missing?(name, include_private = false)
      @values.key?(name.to_s) || super
    end

    def freeze_value(value)
      case value
      when Hash then Node.new(value)
      when Array then value.map { |item| freeze_value(item) }.freeze
      when String then value.dup.freeze
      else value.freeze
      end
    end

    def export_value(value, type)
      case value
      when Node then value.to_h((type == :indifferent) ? nil : type)
      when Array then value.map { |item| export_value(item, type) }
      when String then value.dup
      else value
      end
    end
  end
end
