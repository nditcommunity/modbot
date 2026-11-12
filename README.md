<img src="assets/ndit-bot.png" align="right" width="180" alt="NDIT bot mascot">

# NDIT Slack Bot

A Rails application for the Neurodiversity in Tech Slack workspace. Members can contact moderators and join configured private channels from a slash command. Replies work in channels and direct messages.

## Commands

- `/mods <message>` sends a report to the moderator channel and confirms delivery to the member.
- `/add-to-channel help` lists the private channels available through the bot.
- `/add-to-channel <name>` invites the member to a configured private channel.

The current channel arguments are:

- `bipoc`: for anyone who identifies as BIPOC.
- `women-nonbinary`: for women and nonbinary people.
- `queer`: for LGBTQIA+ folks.

Arguments also accept underscores, the `intersection-` prefix, and an optional leading `#`. For example, `women_nonbinary` and `#intersection-women-nonbinary` select the same channel. Updating the configuration does not rename or archive Slack channels.

## Requirements

- [Ruby 3.3.1](https://www.ruby-lang.org/en/documentation/installation/), as specified in `.ruby-version` and `Gemfile`.
- Bundler and the dependencies in `Gemfile.lock`.
- Rails 8.1.4.1 or a newer compatible 8.1 patch release, installed by Bundler.
- A Slack app and workspace for integration testing or deployment.

A Ruby version manager such as [rbenv](https://github.com/rbenv/rbenv) or [RVM](https://rvm.io) is recommended. With RVM:

```sh
rvm install ruby-3.3.1
cd slack-bot
rvm use ruby-3.3.1@slack-bot --create
gem install bundler
bundle install
```

The repository's `.ruby-gemset` uses `slack-bot`. Run `bundle install` in that gemset even if dependencies were previously installed in another one. With another version manager, select Ruby 3.3.1 and run the same Bundler commands from the repository root.

## Configuration

Set these environment variables in your local environment or hosting service:

| Variable | Purpose |
| --- | --- |
| `SLACK_OAUTH_TOKEN` | Bot user OAuth token for the installed Slack app. The runtime client explicitly uses this token. |
| `SLACK_SIGNING_SECRET` | Signing secret from the Slack app's Basic Information page. Required for signed requests; production will not start without it. |
| `SECRET_KEY_BASE` | Rails secret key base. Generate a value with `bundle exec rails secret`. |
| `MOD_CHANNEL` | ID of the channel that receives moderator reports. |

For local development, `dotenv-rails` can load these from a gitignored `.env` file. Do not commit credentials. A channel ID can be found in Slack's channel details or its browser URL.

### Workspace-specific settings

Before using this application in another workspace, review:

- [`SlackMessage::CHANNELS`](app/models/slack_message.rb): private-channel IDs and descriptions used for invitations and help text.
- [`Slack::Client::SUPPORT_CHANNEL`](app/lib/slack/client.rb): the channel link in error messages, currently NDIT's `#ndit-meta`.
- [`config/initializers/sentry.rb`](config/initializers/sentry.rb): the production Sentry destination and sampling configuration. Replace or remove the existing project destination before deploying a fork. Production tracing currently samples all transactions; development and test reports are disabled.

## Running locally

Install dependencies, configure the environment, then start the application:

```sh
bundle exec rails server
```

The server runs at `http://localhost:3000`. Slack must reach a public HTTPS URL for live slash-command testing. Use a separate test workspace and test channels: requests that send messages or invite members change the configured workspace.

## Installing and deploying the Slack app

1. [Create a Slack app](https://api.slack.com/apps). Use [`.slack_manifest.yml`](.slack_manifest.yml) as a starting point, updating its name for your workspace.
2. Review OAuth scopes. The manifest currently includes `users:read`, `im:write`, `chat:write`, `channels:join`, `channels:manage`, `groups:write`, `groups:read`, `im:read`, and `channels:read`. It does not include `commands` or define the slash commands. Add the slash-command capability and configure both commands below in the app settings. These existing scopes are not a validated minimum; see the [permission review](SECURITY.md#slack-permission-review) before changing installed grants.
3. Install the app to the intended workspace and use its bot user OAuth token for `SLACK_OAUTH_TOKEN`. Reinstall it if approved scope changes require new grants.
4. Add the bot to the moderator channel and each private channel it is configured to invite members to. An account's membership does not give the bot membership.
5. Deploy the Rails application to Heroku or another Ruby-compatible host. Set the four environment variables above, use `RAILS_ENV=production`, and expose the application over HTTPS.
6. Configure these slash commands, replacing the example host with your application's public URL:

| Command | Request URL | Description | Usage hint |
| --- | --- | --- | --- |
| `/mods` | `https://your-app.example/mod` | Send a message to the moderators | `<message to mods>` |
| `/add-to-channel` | `https://your-app.example/channels` | Join a private channel | `help or <channel name>` |

7. Run the checks below and test `/mods`, private-channel help, an allowed join, an unknown channel, and replies from a direct message in the test workspace. Confirm that the report reaches the intended moderator channel and that invitations target the configured private channels.

The GitHub Pages workflow publishes API documentation only. It does not deploy the running Slack bot.

## Security behavior

- Slack webhook signatures are verified against the exact request body. Missing, invalid, or expired signatures return `403`.
- POST bodies larger than 64 KiB return `413`, including URL-encoded content. The hosting proxy still needs appropriate connection limits and timeouts.
- Moderator reports must be nonblank and at most 12,000 characters, while fitting the encoded body limit. Invalid report text returns `400`.
- Report content is displayed as literal plain text. Command text and response URLs are filtered from logs and Sentry reports.

See [SECURITY.md](SECURITY.md) for the security checks, privacy protections, deployment requirements, and Slack permission review.

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

The [Ruby workflow](.github/workflows/ruby.yml) runs lint, tests, eager loading, production boot, dependency auditing, and Brakeman. [CodeQL](.github/workflows/codeql.yml) provides a separate analysis. Check the results for the latest PR commit before merging.

## Updating dependencies

For a targeted update, run `bundle update <gem-name>`, review the `Gemfile.lock` changes, and rerun the checks above. Use `bundle update` when intentionally updating all permitted dependencies. Keep the Ruby version in the application and workflows consistent.

## API documentation

Generate a fresh local copy with YARD:

```sh
bundle exec yard doc --no-cache --asset assets --output-dir tmp/api-docs 'app/**/*.rb'
```

Open `tmp/api-docs/index.html` to view it. This output is gitignored.

The [Pages workflow](.github/workflows/static.yml) generates documentation from the current source in a clean temporary directory, checks the generated pages, and uploads the artifact. It does not publish the committed `doc/` snapshot. Pull requests build and validate the documentation without deploying it. Pushes to `main`, or a manual workflow run on `main`, also run deployment.

To publish a repository's documentation, set **Settings → Pages → Build and deployment → Source** to **GitHub Actions**. After deployment succeeds, use the URL shown by the `github-pages` environment or the deploy job. A successful documentation build alone does not confirm that the site is published.
