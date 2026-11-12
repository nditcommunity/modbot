# Configuration and hosting

[Back to README](../README.md)

This guide covers maintaining NDIT's existing Mod Bot and Slack integration.

## Hosted application

Mod Bot runs on [Heroku](https://nd-in-tech-bot-e4683f501c14.herokuapp.com/). Its source is [nditcommunity/modbot](https://github.com/nditcommunity/modbot). The current runtime uses Ruby 3.3.1 and Rails 8.1.4.1 or a newer compatible 8.1 patch release.

Keep the deployed revision aligned with the intended commit on `main`. A GitHub merge or passing CI does not by itself confirm a successful Heroku release. Follow the [deployment checks](development.md#deployment-checks) after changes.

## Hosting configuration

The hosting service supplies these environment variables:

| Variable | Purpose |
| --- | --- |
| `SLACK_OAUTH_TOKEN` | Bot user OAuth token for NDIT's installed Slack app. The runtime client explicitly uses this token. |
| `SLACK_SIGNING_SECRET` | Signing secret for the installed Slack app. Required for signed requests; production will not start without it. |
| `SECRET_KEY_BASE` | Rails secret key base for the hosted application. |
| `MOD_CHANNEL` | ID of the NDIT channel that receives moderator reports. |

Production uses `RAILS_ENV=production`. Keep credentials in the hosting service's protected configuration, not source files, logs, or documentation.

## Channel configuration

- [`SlackMessage::CHANNELS`](https://github.com/nditcommunity/modbot/blob/main/app/models/slack_message.rb) contains the private-channel IDs and descriptions used for invitations and help text. Keep these aligned with channel renames and the channels offered by `/add-to-channel`.
- [`Slack::Client::SUPPORT_CHANNEL`](https://github.com/nditcommunity/modbot/blob/main/app/lib/slack/client.rb) links error messages to NDIT's `#ndit-meta`.
- The bot must belong to the moderator channel and each private channel it invites members to. An admin account's membership does not give the bot membership.

## Existing Slack integration

NDIT's slash commands use these endpoints on the hosted application:

| Command | Request URL | Purpose |
| --- | --- | --- |
| `/mods` | `https://nd-in-tech-bot-e4683f501c14.herokuapp.com/mod` | Send a message to the moderators |
| `/add-to-channel` | `https://nd-in-tech-bot-e4683f501c14.herokuapp.com/channels` | Show private-channel help or join a configured channel |

If the hosting address changes, verify both command URLs in the existing app's Slack settings. Do not treat the repository's [manifest](https://github.com/nditcommunity/modbot/blob/main/.slack_manifest.yml) as a complete record of the installed app: it does not define these slash commands, and its listed scopes are not a validated minimum. Review [Slack permissions](https://github.com/nditcommunity/modbot/blob/main/SECURITY.md#slack-permission-review) before changing grants or reinstalling the app.

## Error reporting and security

[`config/initializers/sentry.rb`](https://github.com/nditcommunity/modbot/blob/main/config/initializers/sentry.rb) configures NDIT's production Sentry destination and sampling. Production tracing samples all transactions; development and test reporting are disabled. Sensitive request data is filtered before reporting.

See [Security](https://github.com/nditcommunity/modbot/blob/main/SECURITY.md) for webhook validation, request limits, privacy protections, and permission review. See [Maintenance](development.md) for the checks required before and after deployment.
