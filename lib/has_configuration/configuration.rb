# frozen_string_literal: true

require 'active_support/core_ext/hash/indifferent_access'
require 'ostruct'
require 'yaml'

module HasConfiguration # :nodoc:
  class Configuration # :nodoc:
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
      @raw = if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.6.0')
               YAML.safe_load(ERB.new(raw_file(filename)).result, aliases: true)
             else
               YAML.safe_load(
                 ERB.new(raw_file(filename)).result,
                 [],  # whitelist_classes
                 [],  # whitelist_symbols
                 true # allow aliases
               )
             end
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
      @options[:file] || determine_filename_from_class ||
        raise(
          ArgumentError,
          'Unable to resolve filename, please add :file parameter to has_configuration'
        )
    end

    def determine_filename_from_class
      return unless @class_name

      filename = "#{@class_name.downcase}.yml"
      defined?(Rails) ? Rails.root.join('config', filename).to_s : filename
    end

    def environment
      return @options[:env] if @options.key?(:env)
      return Rails.env.to_s if defined?(Rails)
    end

    def deep_structify(hash)
      hash ||= {}
      result = hash.transform_values { |v| v.is_a?(Hash) ? deep_structify(v) : v }
      OpenStruct.new(result) # rubocop:disable Style/OpenStructUse
    end

    def deep_symbolized_hash
      @deep_symbolized_hash ||= deep_transform_keys(@hash) do |key|
        key.respond_to?(:to_sym) ? key.to_sym : key
      end
    end

    def deep_stringified_hash
      @deep_stringified_hash ||= deep_transform_keys(@hash, &:to_s)
    end

    # from Rails (/active_support/core_ext/hash/keys.rb)
    def deep_transform_keys(hash, &block)
      hash&.each_with_object({}) do |(key, value), result|
        result[yield(key)] = value.is_a?(Hash) ? deep_transform_keys(value, &block) : value
      end
    end
  end
end
