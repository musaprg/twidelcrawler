# encoding: utf-8

require 'pg'
require 'yaml'
require 'twitter'
# require 'net/https'
# require 'oauth'
# require 'cgi'
# require 'json'

twconf = YAML.load_file("config.yml")["twitter"]
dbconf = YAML.load_file("config.yml")["db"]["development"]


rest = Twitter::REST::Client.new do |config|
  config.consumer_key        = twconf["consumer_key"]
  config.consumer_secret     = twconf["consumer_secret"]
  config.access_token        = twconf["access_token"]
  config.access_token_secret = twconf["access_token_secret"]
end
stream = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = twconf["consumer_key"]
  config.consumer_secret     = twconf["consumer_secret"]
  config.access_token        = twconf["access_token"]
  config.access_token_secret = twconf["access_token_secret"]
end

stream.user do |status|
  case status
  when Twitter::Tweet then
    # username = status.user.screen_name
    # contents = status.text
    # str = username + ":" + contents
    # puts str
  when Twitter::Streaming::DeletedTweet then
    user = rest.user(status.user_id)
    rest.update("#{user.name}(@#{user.screen_name})のツイ消しを検出しました。") if user.id != 817254158839332865
  end
end

# initialize db connection
connection = PG::connect(@dbconf)
# close db connection
connection.finish if @connection
