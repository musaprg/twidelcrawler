# encoding: utf-8

require 'pg'
require 'yaml'
require 'twitter'
require 'tweetstream'

twconf = YAML.load_file("config.yml")["twitter"]
dbconf = YAML.load_file("config.yml")["db"]["product"]

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = twconf.consumer_key
  config.consumer_secret     = twconf.consumer_secret
  config.access_token        = tfconf.access_token
  config.access_token_secret = tf.conf.access_token_secret
end

stream = TweetStream::Client.new do |config|
   config.consumer_key          = twconf.consumer_key
   config.consumer_secret       = twconf.consumer_secret
   config.oauth_token           = twconf.access_token
   config.oauth_token_secret    = twconf.access_token_secret
end

# initialize db connection
connection = PG::connect(@dbconf)

# check table exists. if not, create new one.
begin
    result = connection.exec("
      SHOW TABLES LIKE 'timeline'
    ")
    p result
end

stream.userstream do |status|
   puts " #{status.user.name} -> #{status.text}\n\n"
end

# close db connection
connection.finish if @connection
