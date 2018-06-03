require 'active_support/core_ext/hash/indifferent_access'
require 'ostruct'
require 'yaml'

module HasConfiguration #:nodoc:
  class Configuration #:nodoc:
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
      configuration.send(sym, *args, &block) || super
    end

    def respond_to_missing?(sym, include_private = false)
      configuration.respond_to?(sym, include_private)
    end

    def load_file
      @raw = YAML.safe_load(
        ERB.new(raw_file(filename)).result,
        [],  # whitelist_classes
        [],  # whitelist_symbols
        true # allow aliases
      )
    end

    def init_hash
      @hash = (@raw || {}).with_indifferent_access
      @hash = @hash[environment] if environment
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
              'Unable to resolve filename, please add :file parameter to has_configuration'
      end
    end

    def environment
      return @options[:env] if @options.key?(:env)
      return Rails.env.to_s if defined?(Rails)
    end

    def deep_structify(hash)
      hash ||= {}
      result = Hash[hash.map { |k, v| [k, v.is_a?(Hash) ? deep_structify(v) : v] }]
      OpenStruct.new(result)
    end

    def deep_symbolized_hash
      @deep_symbolized_hash ||= deep_transform_keys(@hash) do |key|
        key.respond_to?(:to_sym) ? key.to_sym : key
      end
    end

    def deep_stringified_hash
      @deep_stringified_hash ||= deep_transform_keys(@hash, &:to_s)
    end

    # from Rails 4.0 (/active_support/core_ext/hash/keys.rb)
    def deep_transform_keys(hash, &block)
      result = {}
      if hash
        hash.each do |key, value|
          result[yield(key)] = value.is_a?(Hash) ? deep_transform_keys(value, &block) : value
        end
      end
      result
    end
  end
end
