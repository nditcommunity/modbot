class ApplicationController < ActionController::Base
  def index
    render inline: "<p>Are you looking for <a href='https://github.com/nditcommunity/slack-bot#readme'>the docs</a>?</p>"
  end
end
