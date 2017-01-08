require 'pg'
require 'yaml'
require 'twitter'

twconf = YAML.load_file("config.yml")["twitter"]
dbconf = YAML.load_file("config.yml")["db"]["development"]

class Crawler
  @stream

  def initialize
    @rest = Twitter::REST::Client.new do |config|
      config.consumer_key        = twconf["consumer_key"]
      config.consumer_secret     = twconf["consumer_secret"]
      config.access_token        = twconf["access_token"]
      config.access_token_secret = twconf["access_token_secret"]
    end
    @stream = Twitter::Streaming::Client.new do |config|
      config.consumer_key        = twconf["consumer_key"]
      config.consumer_secret     = twconf["consumer_secret"]
      config.access_token        = twconf["access_token"]
      config.access_token_secret = twconf["access_token_secret"]
    end
  end

  def start_crawling
    @stream.user do |status|
      case status
      when Twitter::Tweet then
        username = status.user.screen_name
    	  contents = status.text
        str = username + ":" + contents
        puts str
      when Twitter:: DeletedTweet then
        @client.update("#{status.user.name}さん(@#{status.user.screen_name})のツイ消しを検出しました。")
      end
    end
  end
end
