# Maintenance

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

## Deployment checks

1. Check that lint, tests, eager loading, production boot, the dependency audit, Brakeman, CodeQL, and the documentation build pass for the exact latest PR commit. Recheck after further edits or conflict resolution.
2. After merging, confirm Heroku deployed the intended `main` commit and the application responds successfully. GitHub Pages publishes documentation only; it does not deploy the Slack bot.
3. Verify the existing Slack command URLs, credentials, bot membership, and private-channel configuration if any of them changed. Run live command checks only with authorization, using designated test channels or a separate test workspace. `/mods` sends a real report and `/add-to-channel` can change channel membership.
4. Check help, an allowed channel request, an unknown channel, moderator-report delivery, and direct-message replies as relevant to the change. Check sanitized application errors if a command fails.

## Documentation checks

The [documentation workflow](https://github.com/nditcommunity/modbot/blob/main/.github/workflows/static.yml) generates YARD pages from the current source in a clean temporary directory, checks the pages and icon, and uploads an artifact. Pull requests validate documentation without publishing it. Runs on `main` also attempt a GitHub Pages deployment.

Check the build results when changing source comments, README content, or assets. If a public documentation site is being used, verify its actual URL after deployment rather than relying on a green workflow alone. The maintenance guides themselves live in this repository.
