# frozen_string_literal: true

require "yaml"
require "has_configuration/node"

module HasConfiguration
  autoload :ERBRenderer, "has_configuration/erb_renderer"
  private_constant :ERBRenderer

  class Configuration < Node
    def initialize(klass, options = {})
      file = options[:file] || default_filename(klass)
      environment = if options.key?(:env)
        options[:env]
      elsif defined?(Rails) && Rails.respond_to?(:env)
        Rails.env.to_s
      end

      values = load_values(file)
      if environment
        unless values.key?(environment.to_s)
          raise ArgumentError, "Missing configuration environment #{environment.inspect} in #{file}"
        end
        values = values.fetch(environment.to_s)
        unless values.is_a?(Hash)
          raise ArgumentError, "Configuration environment #{environment.inspect} must be a mapping in #{file}"
        end
      end

      super(values)
    end

    private

    def default_filename(klass)
      unless klass.name
        raise ArgumentError, "Unable to resolve filename, please add :file parameter to has_configuration"
      end

      name = "#{klass.name.downcase}.yml"
      if defined?(Rails) && Rails.respond_to?(:root) && Rails.root
        File.join(Rails.root.to_s, "config", name)
      else
        name
      end
    end

    def load_values(file)
      source = File.read(file)
      source = render_erb(source, file) if source.include?("<%")
      tree = YAML.parse_stream(source, filename: file.to_s)
      if tree.children.length > 1
        raise ArgumentError, "Configuration must contain a single YAML document in #{file}"
      end
      validate_yaml_keys(tree, file)
      values = YAML.safe_load(source, aliases: true, filename: file.to_s)
      values = {} if values.nil?
      unless values.is_a?(Hash)
        raise ArgumentError, "Configuration must be a mapping in #{file}"
      end
      validate_values(values, file, {})
      values
    end

    def render_erb(source, file)
      begin
        renderer = ERBRenderer
      rescue LoadError
        raise LoadError, "ERB configuration in #{file} requires the optional erb gem; add it to your Gemfile"
      end
      renderer.render(source, file)
    end

    # Inspect the YAML tree before safe_load can silently overwrite duplicates.
    # Merge defaults are not explicit duplicate keys and remain supported.
    def validate_yaml_keys(node, file)
      if node.is_a?(Psych::Nodes::Mapping)
        seen = {}
        node.children.each_slice(2) do |key, _value|
          unless key.is_a?(Psych::Nodes::Scalar)
            raise ArgumentError, "Configuration keys must be strings in #{file}"
          end
          if seen.key?(key.value)
            raise ArgumentError, "Duplicate configuration key at line #{key.start_line + 1} in #{file}"
          end
          seen[key.value] = true
        end
      end
      node.children&.each { |child| validate_yaml_keys(child, file) }
    end

    def validate_values(value, file, ancestors)
      return unless value.is_a?(Hash) || value.is_a?(Array)
      if ancestors.key?(value.object_id)
        raise ArgumentError, "Cyclic configuration alias in #{file}"
      end
      ancestors[value.object_id] = true
      if value.is_a?(Hash)
        value.each do |key, child|
          unless key.is_a?(String)
            raise ArgumentError, "Configuration keys must be strings in #{file}; quote numeric and boolean keys"
          end
          validate_values(child, file, ancestors)
        end
      else
        value.each { |child| validate_values(child, file, ancestors) }
      end
      ancestors.delete(value.object_id)
    end
  end
end
