Has Configuration
=================

Load configuration settings from a YAML file and adds a class and an instance method `configuration` to an object.

[![License MIT](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://github.com/spickermann/has_configuration/blob/main/MIT-LICENSE)
[![Gem Version](https://badge.fury.io/rb/has_configuration.svg)](http://badge.fury.io/rb/has_configuration)
[![Build Status](https://github.com/spickermann/has_configuration/actions/workflows/CI.yml/badge.svg)](https://github.com/spickermann/has_configuration/actions/workflows/CI.yml)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/a740e5e773aa40e48363117832b8b9ff)](https://app.codacy.com/gh/spickermann/has_configuration/dashboard)
[![Codacy Badge](https://app.codacy.com/project/badge/Coverage/a740e5e773aa40e48363117832b8b9ff)](https://app.codacy.com/gh/spickermann/has_configuration/dashboard)

Installation
------------

Include the gem into your Gemfile:

```ruby
gem 'has_configuration'
```

When you are still on Ruby 1.8 or on Ruby on Rails 2.3:

```ruby
gem 'has_configuration', '~> 0.2.4'
```

When you are still on Ruby 2.4 – 2.7:

```ruby
gem 'has_configuration', '~> 5.0.1'
```

Usage
-----

```ruby
has_configuration
# => loads setting without environment processing from the file #{self.class.name.downcase}.yml

has_configuration file: Rails.root.join('config', 'example.yml'), env: 'staging'
# => loads settings for staging environment from RAILS_ROOT/config/example.yml file
```

**options**

<dl>
<dt>file</dt>
<dd>
  The YAML file to load: Defaults to <code>config/classname.yml</code> if Rails is
  defined, <code>classname.yml</code> otherwise.
</dd>
<dt>env</dt>
<dd>
  The environment to load from the file. Defaults to `Rails.env` if Rails is defined, no default if not.
</dd>

YAML File Example
-----------------

The YAML file may contain defaults. Nesting is not limited. ERB in the YAML file is evaluated.

```yaml
defaults: &defaults
  user: root
  some:
    nested: value
development:
  <<: *defaults
  password: secret
production:
  <<: *defaults
  password: <%= ENV[:secret] %>
```

Configuration Retrieval
-----------------------

If the example above was loaded into a class `Foo` in `production` environment:

```ruby
Foo.configuration                         # => <HasConfiguration::Configuration:0x00...>
Foo.new.configuration                     # => <HasConfiguration::Configuration:0x00...>

# convenient getter methods
Foo.configuration.some.nested             # => "value"

# to_h returns a HashWithIndifferentAccess
Foo.configuration.to_h                    # => { :user => "root", :password => "prod-secret"
                                          #      :some => { :nested => "value" } }
Foo.configuration.to_h[:some][:nested]    # => "value"
Foo.configuration.to_h[:some]['nested']   # => "value"

# force a special key type (when merging with other hashes)
Foo.configuration.to_h(:symbolized)       # => { :user => "root", :password => "prod-secret"
                                          #      :some => { :nested => "value" } }
Foo.configuration.to_h(:stringify)        # => { 'user' => "root", 'password' => "prod-secret"
                                          #      'some' => { 'nested' => "value" } }
```

Contributing
------------

1. [Fork it](http://github.com/spickermann/has_configuration/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new pull request.
