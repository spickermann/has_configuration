# Has Configuration

Load trusted YAML settings into a deeply frozen configuration with class and instance getters.
The core uses Ruby's YAML library and has **no runtime gem dependencies**.
Rails, ERB and ActiveSupport conveniences are optional.

[![License MIT](https://img.shields.io/badge/license-MIT-brightgreen.svg)](MIT-LICENSE)
[![Gem Version](https://badge.fury.io/rb/has_configuration.svg)](https://rubygems.org/gems/has_configuration)
[![Build Status](https://github.com/spickermann/has_configuration/actions/workflows/CI.yml/badge.svg)](https://github.com/spickermann/has_configuration/actions/workflows/CI.yml)

## Installation and supported versions

```ruby
# Gemfile
gem "has_configuration", "~> 7.0"
```

Requires Ruby 3.3 or newer. The supported Ruby series are currently 3.3, 3.4 and 4.0.
Optional Rails integration targets Rails 8.0 and 8.1. Older Ruby/Rails series are not supported.
Supported series are reviewed against their upstream end-of-life dates when preparing releases.
Rails is never loaded or installed by this gem.

## Standalone use

```yaml
# settings.yml
service:
  host: localhost
  enabled: false
  token: null
servers:
  - host: primary.example
  - host: secondary.example
```

```ruby
require "has_configuration"

class Service
  has_configuration file: "settings.yml"
end

Service.configuration.service.host          # => "localhost"
Service.configuration.service.enabled       # => false
Service.configuration.service.token         # => nil
Service.configuration.servers.first.host    # => "primary.example"
Service.new.configuration.equal?(Service.configuration) # => true
```

Requiring the gem retains the original global integration: the `has_configuration`
class macro is available through `Object`. Classes are configured only when they call it.
Loading occurs once, at that call; later edits to the file are not reloaded automatically.
A later explicit call to `has_configuration` replaces that class's configuration only after loading succeeds.

### Files and environments

- `file:` chooses a file, accepting a string or `Pathname`. Without it, the downcased class name
  is used: `Service` loads `service.yml` relative to the current working directory.
  Namespaced classes retain `::` in this filename; use `file:` to choose another convention.
  Anonymous classes require `file:`.
- With an initialized Rails already loaded, the default file is under `Rails.root/config`
  and the default environment is `Rails.env`.
- `env: "production"` or `env: :production` selects that top-level mapping.
  `env: nil` explicitly reads the entire file, including under Rails.
  The legacy `env: false` spelling also disables selection.
- Missing environments and environments that are not mappings raise `ArgumentError` immediately.
  An explicitly empty environment (`production: {}`) is valid.
- Without environment selection, an empty file, YAML `null` or `{}` is an empty configuration.
  Other scalar roots, array roots and multiple YAML documents raise `ArgumentError`.

```ruby
class Service
  has_configuration file: Rails.root.join("config", "service.yml"), env: "production"
end
```

### Strict, unambiguous keys

Configuration keys must be strings and must not be repeated within a YAML mapping.
Quote keys such as `"1"`, `"on"`, `"off"`, `"yes"` and `"true"`: YAML may otherwise interpret
these as numbers or booleans. Duplicate and non-string keys raise `ArgumentError`.

A missing dot getter raises `NoMethodError` at every level. A present `false` or `null`
returns `false` or `nil`, and `respond_to?` recognizes both. Getters accept no arguments or blocks.

Existing Ruby and configuration methods take precedence over configuration keys.
For keys such as `class`, `send`, `respond_to?` and `to_h`, or keys containing spaces,
use a hash export and `fetch`:

```ruby
hash = Service.configuration.to_h
hash.fetch("service").fetch("host")  # strict: raises KeyError if missing
hash.fetch("service").key?("token") # distinguishes missing from present nil
hash["missing"]                      # ordinary Hash behavior: nil
```

This collision rule applies equally to nested mappings, including mappings inside arrays.
The dot-access objects are `HasConfiguration::Node` instances, not OpenStructs.

## Immutable settings, mutable exports

Configurations, nested nodes, arrays and strings are frozen. Setters are not provided.
To derive runtime settings, work on a copy outside this gem:

```ruby
settings = Service.configuration.to_h
settings["service"]["host"] = "override.example"
# Service.configuration.service.host remains "localhost".
```

Every `to_h` call creates a new, independently mutable snapshot, including nested arrays
and string values. It never exposes the original settings or a shared cached hash.

```ruby
Service.configuration.to_h              # ordinary Hash with string keys
Service.configuration.to_h(:stringify)  # same, explicitly
Service.configuration.to_h(:symbolized) # symbol keys at every depth, including arrays
```

For compatibility, unknown export modes retain the default string-keyed behavior.
If repeatedly working with a large export, retain that local hash rather than exporting again.
The return type does not change merely because Rails or ActiveSupport is loaded.

### Optional indifferent access

Add `activesupport` to your application's Gemfile (supported integration: 8.0 or newer), then request:

```ruby
settings = Service.configuration.to_h(:indifferent)
settings[:service]["host"] # => "localhost"
```

Only this export attempts to load ActiveSupport's indifferent-access extension.
It returns an independent, mutable `ActiveSupport::HashWithIndifferentAccess`.
If the optional gem is unavailable, a `LoadError` explains which dependency to add.
There is no need to install Rails for this feature.

## Inheritance

```ruby
class Service
  has_configuration file: "settings.yml"
end

class ChildService < Service
end

ChildService.configuration.equal?(Service.configuration) # => true

class SpecializedService < Service
  has_configuration file: "specialized.yml"
end
```

A subclass uses its nearest configured ancestor. A subclass declaration replaces the inherited
configuration completely; keys are **not merged**. Parent classes and siblings are unaffected.
Descendants without their own declaration follow their ancestor's current configuration.
Sharing the inherited object is safe because its contents are immutable.

## YAML defaults and optional ERB

```yaml
# service.yml
defaults: &defaults
  host: localhost
  retries: 3
production:
  <<: *defaults
  host: production.example
  token: <%= ENV["secret"].to_s.inspect %>
```

Use the merge entry (`<<`) before explicit overrides, as shown. Repeated aliases and YAML merge
sequences are supported. Duplicate explicit keys and cyclic aliases are rejected.

Only files containing ERB markup (`<%`) attempt to load `erb`. Add `gem "erb"` to your application's
Gemfile when using templates; depending on Ruby it may already be available as a default gem.
A template without available ERB raises an actionable `LoadError`; it is never silently treated as plain YAML.
ERB runs once before YAML parsing. `ENV` requires string keys. The example renders an unset `secret`
as an empty string; use `ENV.fetch("secret")` if absence should instead be an error.

**Only load trusted configuration files.** ERB executes Ruby code with the process's privileges.
`YAML.safe_load` does not sandbox ERB. YAML aliases are enabled for defaults, but cyclic structures
are rejected. Arbitrary Ruby object tags, Symbol tags and unquoted dates are not permitted;
quote dates when they should be strings. File errors, YAML parsing errors and ERB evaluation
errors propagate; YAML syntax errors include the filename. Own validation errors identify the
file without including configuration values. Missing-getter errors do not print the configuration contents.

## Migrating from 6.x

Version 7.0.0 intentionally changes these contracts:

- Ruby <3.3 and Rails <8.0 are no longer supported.
- ActiveSupport and OpenStruct are no longer runtime dependencies. Add optional gems to your own
  Gemfile where needed; request `:indifferent` explicitly for the old hash convenience.
- `to_h` defaults to an ordinary string-keyed Hash. Replace `to_h[:key]` with
  `to_h.fetch("key")`, `to_h(:symbolized).fetch(:key)`, or an explicit indifferent export.
- Mutating any export no longer changes configuration. Dot values are deeply frozen and have no
  setters. Store mutable overrides outside the configuration object.
- Nested mapping values are read-only nodes, also within arrays. Replace OpenStruct-specific
  operations and Hash operations on dot-access array elements with a `to_h` export.
- Missing dot keys now fail consistently at every depth; explicitly present `false` and `nil` work.
- Missing/invalid environments, non-mapping roots, cyclic aliases, duplicate keys and non-string
  keys are rejected when loading. Quote numeric/boolean keys and remove duplicates.
- Ruby methods take precedence over keys on every node; use hash `fetch` for collisions.
- Subclasses inherit configuration until they declare a complete replacement.

## Development and release

```sh
bundle install
bundle exec rake
```

The default task runs the tests and Standard.
Run `bundle exec ruby script/verify_package.rb` to build and smoke-test an isolated installation,
and `bundle exec ruby -Ilib script/benchmark.rb` for a reproducible local benchmark. Development dependencies are declared in the Gemfile;
`Gemfile.lock` pins the development tools. The optional Rails environments have separate
`gemfiles/rails_8.0.gemfile.lock` and `gemfiles/rails_8.1.gemfile.lock` files. CI installs
these committed versions in frozen mode; none adds a runtime dependency to the gem.

```sh
BUNDLE_GEMFILE=gemfiles/rails_8.0.gemfile bundle install
RAILS_VERSION=8.0 BUNDLE_GEMFILE=gemfiles/rails_8.0.gemfile bundle exec rake
# Use 8.1 in both places to test Rails 8.1.
```

Update each environment intentionally with `bundle update --all`, review the lockfile changes,
and commit them together. The lockfiles cover Ruby source gems, macOS arm64 and Linux platforms.
See [RELEASING.md](RELEASING.md) for the compatibility matrix, package checks and manual release procedure.
