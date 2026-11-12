class ApplicationController < ActionController::Base
  def index
    render inline: "<p>Are you looking for <a href='https://github.com/nditcommunity/modbot#readme'>the docs</a>?</p>"
  end
end
