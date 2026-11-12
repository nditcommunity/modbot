source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.1"

gem "rails", "~> 8.1.4", ">= 8.1.4.1"
gem "puma", "~> 7.2.1"
gem "sentry-ruby"
gem "sentry-rails"
gem "slack-ruby-client"
gem "bootsnap", ">= 1.4.4", require: false

group :development, :test do
  gem "dotenv-rails"
  gem "pry"
  gem "standard"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
end

group :development do
  gem "rack-mini-profiler", "~> 2.0"
  gem "listen", "~> 3.3"
  gem "yard"
end

group :test do
  gem "rspec"
  gem "rspec-rails"
  gem "simplecov"
  gem "webmock"
end
