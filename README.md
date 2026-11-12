# NDIT Slack Bot

This application lets Slack members send messages to moderators and add themselves to configured private channels. Replies work in channels and direct messages.

## System Requirements

**NOTE: if you want to use a version manager, please skip to the next section. Using a version manager is highly recommended.**

This application uses [Ruby 3.3.1](https://www.ruby-lang.org/en/documentation/installation/). You'll need the following
- [RubyGems](https://rubygems.org/pages/download) (installed with rvm)
- bundler (`gem install bundler`)
- required libraries (run `bundle install` from the application home directory)

### If you want to use a version manager

You can use either [rbenv](https://github.com/rbenv/rbenv) or [rvm](https://rvm.io). Further instructions assume use of rvm.
1. Install rvm.
2. `rvm install ruby-3.3.1`
3. `cd` into the `slack-bot` directory
4. This should create a `slack-bot` gemset (a self-contained set of installed gems to avoid conflicts).
5. `gem install bundler`
6. `bundle install`
7. You are good to go!

## Running Locally

You need four environment variables set:

1. `SLACK_OAUTH_TOKEN`
2. `SLACK_SIGNING_SECRET`
3. `SECRET_KEY_BASE`
4. `MOD_CHANNEL`

Get the moderator channel ID by opening the channel in Slack in a browser and looking at the URL. Get the bot token and signing secret from your Slack app settings. Once these are set, start the web application:

`bundle exec rails server`

The app handles Slack slash-command requests. Requests that send messages or invite members affect the configured workspace, so use a test workspace for manual testing.

## Running tests

`bundle exec rspec`
That's it!

## Running the linter

`bundle exec standardrb --fix`

## Deploying to Slack

1. Follow instructions and [create a new slack app](https://api.slack.com/authentication/basics)
2. Add the following Bot Token scopes to your slack app: `users:read`, `im:write`, `chat:write`, `channels:join`, `channels:manage`, `groups:write`, `groups:read`, `im:read`, and `channels:read`. *OR* copy `.slack_manifest.yml` and update the app name.
3. Create a new app in Heroku or your hosting service of choice. Set `SECRET_KEY_BASE`, `SLACK_OAUTH_TOKEN`, `SLACK_SIGNING_SECRET`, and `MOD_CHANNEL` as environment variables.
4. Deploy the app.
5. Go to your app in Slack, then to slash commands, and create the moderator command:

- Command: `/mods`
- Request URL: `https://your-app.herokuapp.com/mod`
- Short Description: `Notifies the mods channel`
- Usage Hint: `<message to mods>`

For private-channel access, point a slash command at `https://your-app.herokuapp.com/channels`. Members can pass `help` to see available channels or a channel name to join. Configure channel IDs and descriptions in `SlackMessage::CHANNELS`.

The available channel arguments are `bipoc`, `women-nonbinary`, and `queer`. The `women-nonbinary` option uses the shared women/nonbinary channel ID. Updating this list does not rename or archive Slack channels. Channel arguments also accept underscores, the `intersection-` prefix, and an optional leading `#`.

## Updating the gems

Dependabot is turned on, but if you want to do it manually, run:

`bundle update`

## Updating the documentation

Regenerate the API documentation with `bundle exec yard doc 'app/**/*.rb'`. The generated `doc` directory is published by the Pages workflow.
