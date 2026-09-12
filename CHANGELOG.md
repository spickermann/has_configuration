# Changelog

## 7.0.0 (2026-09-12)

### Breaking changes

* Require Ruby >= 3.3; optional Rails/ActiveSupport integration targets 8.0 and newer.
* Replace mutable OpenStruct views with deeply frozen read-only configuration nodes.
* Return independent, mutable, string-keyed Hash snapshots from `to_h`; retain recursive
  `:symbolized` and `:stringify` exports, and offer explicit optional `:indifferent` exports.
* Remove mandatory ActiveSupport and OpenStruct dependencies; load ERB only for templates.
* Raise on missing dot keys at every depth and on missing or invalid environments at load time.
* Require unique string YAML keys and mapping roots; reject cyclic aliases and multiple YAML documents.
* Inherit the nearest ancestor's configuration unless a subclass declares a complete replacement.
* Reserve existing Ruby/API methods on all nodes; use hash exports for colliding keys.

### Fixes

* Preserve existing `false` and `nil` values and accurate `respond_to?` results.
* Prevent setters from mutating one view before raising, and eliminate inconsistent cached views.
* Traverse hashes and arrays recursively for dot access and key conversion.
* Support standalone loading without preloaded Rails or ERB and explain missing optional gems.
* Preserve YAML defaults and report syntax errors with their filename.
* Include README.md and CHANGELOG.md in the gem, and make package metadata independent of build Ruby.
* Update development dependencies and CI to Ruby 3.3/3.4/4.0 with optional Rails 8.0/8.1.
* Replace broad Rails/file mocks with regression, subprocess and real Rails application tests.
* Correct ENV examples and document trust assumptions, immutable settings and migration from 6.x.

*6.0.0 (December 25, 2023)*

* Ensure Ruby 3.3 compability
* Ensure Rails 7.1 compability
* Ensure Ruby 3.2 compability
* Ensure Ruby 3.1 compability
* Switch from Travis CI to GitHub Actions
* Switch from Rubocop to Standard
* Stop testing against Ruby 2.7
* Stop testing against Ruby 2.6
* Stop testing against Ruby 2.5

*5.0.1 (December 28, 2020)*

* Ensure Rails 6.1 compability
* Ensure Ruby 3.0 compability

*5.0.0 (April 12, 2020)*

* Ensure Rails 6.0 compability
* Ensure Ruby 2.7 compability
* Drops support for Ruby 2.2
* Drops support for Ruby 2.3
* Improves performance by using methods introduced with Ruby 2.4
* Stop testing against Ruby 2.4

*4.0.0 (March 15, 2019)*

* Drop support for Rails `<4.2.2` (remove CVE-2015-3227 warning)

*3.0.1 (March 04, 2019)*

* Adds `rubocop-rspec`
* Ensure Ruby 2.6 compability (remove deprecation warning)

*3.0.0 (January 16, 2017)*

* Drops support for Ruby 2.1
* Ensure Ruby 2.5 compability

*2.0.0 (January 16, 2017)*

* Drops support for Ruby 1.9 and 2.0
* Use `YAML.safe_load` (which was introduced in Ruby 2.1.0)
* Ensure Ruby 2.4.2 compability
* Ensure Ruby 2.3.5 compability
* Ensure Ruby 2.2.8 compability
* Ensure Ruby 2.1.10 compability

*1.0.0 (April 7, 2015)*

* Drops support for Ruby 1.8.x and Rails 2.3.x
* Adds Rubocop

*0.2.4 (April 7, 2015)*

* Reorganises RSpec configuration
* Adds support for Ruby 2.2.x
* Improves README.md

*0.2.3 (June 7, 2014)*

* Adds coveralls
* Adds support for Ruby 2.1.x
* Updates to RSpec 3.0

*0.2.2 (December 19, 2013)*

* Fixes various edge cases

*0.2.1 (October 10, 2013) YANKED*

* Adds documentation
* Improves specs

*0.2.0 (October 08, 2013) YANKED*

* Fixes Ruby 1.8 compatibility

*0.1.0 (October 08, 2013) YANKED*

* Initial version
