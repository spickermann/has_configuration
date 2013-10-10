Has Configuration
=================

Load configuration settings from a yaml file and adds a class and an instance method `configuration` to an object.

[![Gem Version](https://badge.fury.io/rb/has_configuration.png)](http://badge.fury.io/rb/has_configuration)
[![Build Status](https://travis-ci.org/spickermann/has_configuration.png)](https://travis-ci.org/spickermann/has_configuration)
[![Code Climate](https://codeclimate.com/github/spickermann/has_configuration.png)](https://codeclimate.com/github/spickermann/has_configuration)
[![Dependency Status](https://gemnasium.com/spickermann/has_configuration.png)](https://gemnasium.com/spickermann/has_configuration)

Installation
------------

Include the gem in your Gemfile:

```ruby
gem "has_configuration"
```

Usage
-----

```ruby
has_configuration
# => loads setting without environment processing from the file #{self.class.name.downcase}.yml

has_configuration :file => Rails.root.join('config', 'example.yml'), :env => 'staging'
# => loads settings for staging environment from RAILS_ROOT/config/example.yml file
```

**options**

<dl>
<dt>file</dt>
<dd>
  The yml file to load: Defaults to <code>config/classname.yml</code> if Rails is
  defined, <code>classname.yml</code> otherwise.
</dd>
<dt>env</dt>
<dd>
  The environment to load from the file. Defaults to `Rails.env` if Rails is defined, no default if not.
</dd>

YAML File Example
-----------------

The yaml file may contain defaults. Nesting is not limited. ERB in the yaml file is evaluated.

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
  password: <%= ENV[:secret] &>
```

Configuration Retrieval
-----------------------

If the example above was loaded into a class `Foo` in `production` environment:

```ruby
Foo.configuration                         # => <HasConfiguration::Configuration:0x00...>
foo.new.configuration                     # => <HasConfiguration::Configuration:0x00...>

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
