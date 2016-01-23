Has Configuration
=================

Load configuration settings from a yaml file and adds a class and an instance method `configuration` to an object.

[![License MIT](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://github.com/spickermann/has_configuration/blob/master/MIT-LICENSE)
[![Gem Version](https://badge.fury.io/rb/has_configuration.svg)](http://badge.fury.io/rb/has_configuration)
[![Build Status](https://travis-ci.org/spickermann/has_configuration.svg)](https://travis-ci.org/spickermann/has_configuration)
[![Coverage Status](https://coveralls.io/repos/spickermann/has_configuration/badge.svg?branch=master)](https://coveralls.io/r/spickermann/has_configuration?branch=master)
[![Code Climate](https://codeclimate.com/github/spickermann/has_configuration/badges/gpa.svg)](https://codeclimate.com/github/spickermann/has_configuration)
[![Dependency Status](https://gemnasium.com/spickermann/has_configuration.svg)](https://gemnasium.com/spickermann/has_configuration)

Installation
------------

Include the gem to your Gemfile:

```ruby
gem 'has_configuration'
```

If you still use Ruby 1.8 or Ruby on Rails 2.3:

```ruby
gem 'has_configuration', '~> 0.2.4'
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
5. Create new Pull Request
