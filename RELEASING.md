# Releasing has_configuration

Releases are manual. There is no workflow that pushes gems or creates releases automatically.
The registry is https://rubygems.org and the source repository is
https://github.com/spickermann/has_configuration.

## Prepare and review

1. Review the changes and choose a Semantic Versioning version in `lib/version.rb`.
   Breaking API or minimum-Ruby changes require a major version.
2. Run `bundle update` to test fresh development dependencies; the application-style local
   lockfile is intentionally not committed. Keep declared development version ranges current.
3. Run `bundle exec rake` on supported Ruby series (currently 3.3, 3.4 and 4.0).
   CI repeats this with `RAILS_VERSION=8.0` and `RAILS_VERSION=8.1` for optional Rails integration.
   Set the same environment variable for both `bundle install` and `bundle exec rake`.
   These jobs install railties (the Rails application core), not the full Rails meta-gem.
4. Verify the release against current upstream Ruby and Rails support policies. A declared
   minimum is not evidence that every future version works. Record exact tested versions.
5. Date the changelog, review the README migration notes, then build the package:

   ```sh
   gem build has_configuration.gemspec
   gem specification ./has_configuration-VERSION.gem files
   gem specification ./has_configuration-VERSION.gem dependencies
   shasum -a 256 ./has_configuration-VERSION.gem
   ```

   The package must contain README.md, CHANGELOG.md, RELEASING.md, MIT-LICENSE and the library.
   It must declare Ruby >=3.3 and no runtime gem dependencies. The file list and dependencies
   must not depend on the Ruby version used to evaluate the gemspec. Compare builds under the
   same RubyGems version and SOURCE_DATE_EPOCH if checking byte-for-byte reproducibility;
   metadata written by different RubyGems versions can differ.
6. Install the exact built artifact into a temporary `GEM_HOME` with an isolated `GEM_PATH`.
   Run `bundle exec ruby script/verify_package.rb ./has_configuration-VERSION.gem` to check
   that exact artifact without rebuilding it (omit the argument to build a temporary package).
   From outside the source checkout, require `has_configuration`, load plain YAML and verify
   strict getters, freezing, independent exports and inheritance. Nothing may preload Rails,
   ActiveSupport, OpenStruct or ERB for this smoke test. Test a template separately, including
   the error when ERB is unavailable. Test optional indifferent access and Rails under their
   explicitly installed dependencies. Confirm the gem loaded from the installed directory.
7. Confirm RubyGems ownership and a suitably scoped publishing credential/MFA, plus repository
   push access. Do not print tokens or include credentials in logs. Credential presence alone
   does not prove publishing permission.
8. Review the version, exact artifact/checksum, changelog, migration impact, test results and
   limitations. Obtain the maintainer's explicit release approval for the intended external
   actions before creating a tag, pushing code/tags, publishing a gem or creating a GitHub release.

## Publish after approval

Use the approved, clean release commit and artifact. Tag names use `vVERSION` consistently;
historical tags use mixed conventions and must not be rewritten.

1. Push the approved release commit to the agreed branch.
2. Create an annotated `vVERSION` tag at that commit and push that tag.
3. Publish the exact reviewed artifact with `gem push --host https://rubygems.org FILE.gem`.
4. Create a GitHub release only if explicitly included in the release approval; it is optional.
5. Query RubyGems for the exact version and confirm metadata, dependency list and package checksum.
   Download/install that registry version in another isolated environment and run the smoke test.
   Link the versioned RubyGems page in the release report.

Stop on failed external actions, record which actions succeeded, and resolve the cause before
continuing. Never claim publication succeeded from a local build or a successful Git push alone.
Never retry a conflicting version by silently changing its number or replacing an existing tag.
