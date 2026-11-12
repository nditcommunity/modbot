<img src="assets/ndit-bot.png" align="right" width="180" alt="Mod Bot mascot">

# Mod Bot

Mod Bot helps members of the Neurodiversity in Tech Slack workspace contact moderators and join configured private channels. It is a Ruby on Rails application with replies in channels and direct messages.

## Commands

- `/mods <message>` sends a report to the moderator channel and confirms delivery to the member.
- `/add-to-channel help` lists the private channels available through the bot.
- `/add-to-channel <name>` invites the member to a configured private channel.

The current channel arguments are `bipoc`, `women-nonbinary`, and `queer`. Help explains who each channel is for. Arguments also accept underscores, the `intersection-` prefix, and an optional leading `#`.

## Getting started

Use Ruby **3.3.1** and Bundler. The application uses Rails **8.1.4.1** or a newer compatible 8.1 patch release.

```sh
git clone https://github.com/nditcommunity/modbot.git
cd modbot
bundle install
```

Set `SLACK_OAUTH_TOKEN`, `SLACK_SIGNING_SECRET`, `SECRET_KEY_BASE`, and `MOD_CHANNEL`, then run:

```sh
bundle exec rails server
```

The local server runs at `http://localhost:3000`. Follow the [setup guide](https://github.com/nditcommunity/modbot/blob/main/docs/setup.md) to configure the Slack app, channel IDs, bot membership, and slash commands. Use a separate test workspace for live testing because messages and invitations affect the configured workspace.

## Documentation

- [Setup and deployment](https://github.com/nditcommunity/modbot/blob/main/docs/setup.md): runtime requirements, environment variables, workspace configuration, Slack installation, and hosting.
- [Development and maintenance](https://github.com/nditcommunity/modbot/blob/main/docs/development.md): test commands, security checks, dependency updates, and generated API documentation.
- [Security](https://github.com/nditcommunity/modbot/blob/main/SECURITY.md): webhook validation, privacy protections, and the Slack permission review.

The documentation lives in this repository. GitHub Pages is not required to run the bot or read these guides.

## Checks

```sh
bundle exec standardrb
bundle exec rspec
```

Before merging or deploying, also run the dependency audit, Brakeman, eager-loading check, and production boot check in the [development guide](https://github.com/nditcommunity/modbot/blob/main/docs/development.md). Automated tests mock Slack calls and do not post to a live workspace.
