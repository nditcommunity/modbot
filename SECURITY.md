# Security checks and deployment notes

Run these checks before deploying:

```
bundle exec rspec
bundle exec standardrb
bundle exec bundler-audit check --update
bundle exec brakeman --no-pager
RAILS_ENV=test bundle exec rails zeitwerk:check
```

## Webhooks and privacy

- Every POST body is limited to 64 KiB before Rails, logging, Sentry, or Slack signature verification reads or parses it. Both the declared size and actual stream are checked, including absent or misleading Content-Length. Larger requests return 413 without calling Slack. This is a body-memory bound, not a network timeout or rate limit; the hosting proxy/server still needs suitable connection and request limits.
- The exact accepted bytes are preserved for Slack signature verification. Missing, forged, altered, expired, or malformed signatures return 403. A blank production signing secret prevents startup; empty signing configuration in other environments fails closed.
- Command text and response URLs are filtered from Rails parameters. Sentry request bodies, query strings, headers, cookies, user/extra fields, breadcrumbs, and free-form trace-span data/descriptions are removed. Sentry is enabled only in production so tests and development cannot send reports to the production project.
- Unexpected Slack failures use an opaque reference. Logs retain the error class and reference, not the original exception message or cause. Moderator report content is rendered as literal plain text, split into Slack-sized blocks without truncation. Reports must contain 1–12,000 characters and still fit the encoded request-body limit.
- Tests use synthetic text and mocked Slack calls. They do not post to a live workspace.

## Dependency follow-up

The dependency/security jobs deliberately report findings rather than suppressing them. This patch stays on Rails 7.1 and updates it to the latest 7.1 patch. Rails 7.1 is end-of-life, and current advisories still require a supported Rails release. A framework upgrade and its regression testing are separate follow-up work. A passing application test suite is not a clean security audit.

## Slack permission review

The existing manifest is unchanged. The remaining calls suggest this candidate scope set for a later live installation review:

- `commands`: slash commands.
- `chat:write`: moderator messages and ephemeral replies.
- `im:write`: opening direct conversations for replies.
- `groups:write.invites`: inviting members to configured private channels.

Candidates to remove after validation are `users:read`, `channels:join`, `channels:manage`, `groups:read`, `im:read`, and `channels:read`; replace broad `groups:write` with `groups:write.invites` if the installed app supports the narrower scope. First verify the live app's grants and membership in every configured private/moderator channel, then test `/mods`, private-channel joining, help, and direct-message replies in a separate test workspace. A manifest change alone does not revoke installed grants. Reinstallation or live scope changes require explicit approval.
