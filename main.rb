# encoding: utf-8

# require 'pg'
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

# # initialize db connection
# connection = PG::connect(@dbconf)
#
# connection.exec("create table detect_per_user (\
#   id        int8    primary key,\
#   user_id   int8,\
#   count     int8\
# );")

stream.user do |status|
  case status
  when Twitter::Tweet then
    # username = status.user.screen_name
    # contents = status.text
    # str = username + ":" + contents
    # puts str
  when Twitter::Streaming::DeletedTweet then
    user = rest.user(status.user_id)
    # とりあえずDBに関しては放置
    # dbdata = connection.exec("SELECT * FROM detect_per_user WHERE user_id = #{user.id}")
    # if dbdata.ntuples == 0 then
    #   connection.exec("INSERT INTO detect_per_user (user_id, count) VALUES (#{user.id}, 0)")
    # end
    # connection.exec("UPDATE detect_per_user SET count = #{dbdata.count} + 1 WHERE user_id = #{user.id}")
    rest.update("【#{Time.now.to_s}】#{user.name}(@#{user.screen_name})のツイ消しを検出しました。") if user.id != 817254158839332865
  end
end

# # close db connection
# connection.finish if @connection
