# Development and maintenance

[Back to README](../README.md)

## Tests and checks

Run the same application checks used by CI:

```sh
bundle exec standardrb
bundle exec rspec
RAILS_ENV=test bundle exec rails zeitwerk:check
bundle exec bundler-audit check --update
bundle exec brakeman --no-pager
```

Check production boot with synthetic values and Sentry reporting disabled for that check:

```sh
RAILS_ENV=production \
SECRET_KEY_BASE=synthetic-ci-secret-key-base \
SLACK_SIGNING_SECRET=synthetic-ci-signing-secret \
SENTRY_CURRENT_ENV=ci \
bundle exec rails runner 'puts "Rails #{Rails.version} production boot passed"'
```

These values are for the boot check only, not a live deployment. Automated tests use synthetic content and mocked Slack calls, so they do not post to a live workspace. Passing tests does not verify the live app's credentials, channel membership, or installed scopes.

Use `bundle exec standardrb --fix` only when you want the linter to modify source files. Review its changes before committing.

The [Ruby workflow](https://github.com/nditcommunity/modbot/blob/main/.github/workflows/ruby.yml) runs lint, tests, eager loading, production boot, dependency auditing, and Brakeman. [CodeQL](https://github.com/nditcommunity/modbot/blob/main/.github/workflows/codeql.yml) provides a separate analysis. Check the results for the latest PR commit before merging.

## Updating dependencies

For a targeted update, run `bundle update <gem-name>`, review the `Gemfile.lock` changes, and rerun the checks above. Use `bundle update` when intentionally updating all permitted dependencies. Keep the Ruby version in the application and workflows consistent.

## API documentation

Generate a fresh local copy with YARD:

```sh
bundle exec yard doc --no-cache --asset assets --output-dir tmp/api-docs 'app/**/*.rb'
```

Open `tmp/api-docs/index.html` to view it. This output is gitignored.

The [Pages workflow](https://github.com/nditcommunity/modbot/blob/main/.github/workflows/static.yml) generates documentation from the current source in a clean temporary directory, checks the generated pages, and uploads the artifact. It does not publish the committed `doc/` snapshot. Pull requests build and validate the documentation without deploying it. Pushes to `main`, or a manual workflow run on `main`, also run deployment.

The workflow requires GitHub Pages to be configured with GitHub Actions as its source. Build or deployment success alone does not confirm that its public URL works. These repository guides can be read directly on GitHub without a documentation site.
