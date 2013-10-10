require 'active_support/core_ext/hash/indifferent_access'
require 'ostruct'

module HasConfiguration #:nodoc:all
  class Configuration

    def initialize(klass, options = {})
      @class_name = klass.class.name.downcase
      @options    = options

      load_file
      init_hash
    end

    def to_h(type = nil)
      case type
      when :symbolized  then  deep_symbolized_hash
      when :stringify   then  deep_stringified_hash
      else                    @hash
      end
    end

  private

    def method_missing(sym, *args, &block)
      configuration.send(sym, *args, &block)
    end

    def load_file
      @raw = YAML.load(ERB.new(raw_file(filename)).result)
    end

    def init_hash
      @hash = (@raw || {}).with_indifferent_access
      @hash = @hash[environment]        if environment
    end

    def raw_file(filename)
      File.read(filename)
    end

    def configuration
      @configuration ||= deep_structify(@hash)
    end

    def filename
      case
      when @options[:file]  then @options[:file]
      when defined?(Rails)  then Rails.root.join('config', "#{@class_name}.yml").to_s
      else                       "#{@class_name}.yml"
      end
    end

    def environment
      case
      when @options[:env]   then @options[:env]
      when defined?(Rails)  then Rails.env.to_s
      end
    end

    def deep_structify(hash)
      result = {}
      hash.each do |key, value|
        result[key] = value.is_a?(Hash) ? deep_structify(value) : value
      end
      OpenStruct.new(result)
    end

    def deep_symbolized_hash
      @deep_symbolized_hash ||= deep_transform_keys(@hash) { |key| key.to_sym rescue key }
    end

    def deep_stringified_hash
      @deep_stringified_hash ||= deep_transform_keys(@hash) { |key| key.to_s }
    end

    # from Rails 4.0 (/active_support/core_ext/hash/keys.rb)
    def deep_transform_keys(hash, &block)
      result = {}
      hash.each do |key, value|
        result[yield(key)] = value.is_a?(Hash) ? deep_transform_keys(value, &block) : value
      end
      result
    end

  end
end
