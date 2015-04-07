require 'active_support/core_ext/hash/indifferent_access'
require 'ostruct'
require 'yaml'

module HasConfiguration #:nodoc:all
  class Configuration
    def initialize(klass, options = {})
      @class_name = klass.name
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
      if @options[:file]
        @options[:file]
      elsif @class_name
        filename = "#{@class_name.downcase}.yml"
        defined?(Rails) ? Rails.root.join('config', filename).to_s : filename
      else
        raise ArgumentError,
              "Unable to resolve filename, please add :file parameter to has_configuration"
      end
    end

    def environment
      case
      when @options.keys.include?(:env)   then @options[:env]
      when defined?(Rails)                then Rails.env.to_s
      end
    end

    def deep_structify(hash)
      result = {}
      hash.each do |key, value|
        result[key] = value.is_a?(Hash) ? deep_structify(value) : value
      end if hash
      OpenStruct.new(result)
    end

    def deep_symbolized_hash
      @deep_symbolized_hash ||= deep_transform_keys(@hash) do |key|
        key.respond_to?(:to_sym) ? key.to_sym : key
      end
    end

    def deep_stringified_hash
      @deep_stringified_hash ||= deep_transform_keys(@hash) { |key| key.to_s }
    end

    # from Rails 4.0 (/active_support/core_ext/hash/keys.rb)
    def deep_transform_keys(hash, &block)
      result = {}
      hash.each do |key, value|
        result[yield(key)] = value.is_a?(Hash) ? deep_transform_keys(value, &block) : value
      end if hash
      result
    end
  end
end
