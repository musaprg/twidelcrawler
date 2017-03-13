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
verify_credentials = rest.verify_credentials
myinfo = rest.user(verify_credentials.id)

puts("Bot's screen_name is \"#{myinfo.screen_name}\"")

puts("Initialize DB Connection")

# initialize db connection
connection = PG::connect(@dbconf)
is_table = connection.exec("SELECT relname FROM pg_class WHERE relkind = 'r' AND relname = 'detect_per_user'")
if is_table.ntuples == 0
  connection.exec("CREATE TABLE detect_per_user (\
    id        serial    PRIMARY KEY,\
    user_id   int8,\
    count     int8      DEFAULT '0',\
    accept    boolean   DEFAULT '1'\
  );")
end
is_table = connection.exec("SELECT relname FROM pg_class WHERE relkind = 'r' AND relname = 'tweet_info'")
if is_table.ntuples == 0
  connection.exec("CREATE TABLE tweet_info (\
    id        serial    PRIMARY KEY,\
    tweet_id   int8,\
    tweet_status boolean\
  );")
end

puts("DB connection established")

puts("Start Crawling...")

stream.user do |status|
  case status
  when Twitter::Tweet then
    username = status.user.screen_name
    contents = status.text
    p "statusID is #{status.id}"
    p "retweeted? is #{status.retweeted?}"
    connection.exec("INSERT INTO tweet_info (tweet_id, tweet_status) VALUES (#{status.id}, #{status.retweeted?})")
    #リプライの場合
    if (contents.match(/^@#{myinfo.screen_name}\s/))
      if(contents.match(/やめて/))
        # 監視するのをやめる
        rest.update("@#{status.user.screen_name} ごめんね、解除したよ。また見てほしかったら\"監視して\"って言ってね。【#{Time.now.to_s}】")
        connection.exec("UPDATE detect_per_user SET accept = FALSE WHERE user_id = #{status.user.id}")
      elsif(contents.match(/(.)@[0-9a-zA-Z_]{1,15}を監視/))
        # 特定ユーザーをフォローした上で監視
        target_user = contents.match(/(.)@[0-9a-zA-Z_]{1,15}/)
        target_user = target_user.to_s
        target_user.slice!(/@/)
        rest.follow(target_user)
        rest.update("@#{status.user.screen_name} @#{target_user}の監視を開始したよ。【#{Time.now.to_s}】")
      elsif(contents.match(/監視して/))
        # 監視する
        rest.update("@#{status.user.screen_name} いつも見てるよ。【#{Time.now.to_s}】")
        connection.exec("UPDATE detect_per_user SET accept = TRUE WHERE user_id = #{status.user.id}")
      end
    end
  when Twitter::Streaming::DeletedTweet then
    user = rest.user(status.user_id)
    dbdata = connection.exec("SELECT * FROM detect_per_user WHERE user_id = #{user.id}")
    if dbdata.ntuples == 0
      connection.exec("INSERT INTO detect_per_user (user_id) VALUES (#{user.id})")
    end
    # p dbdata[0]["accept"]
    # puts dbdata[0]["accept"]
    if dbdata.ntuples == 0 || dbdata[0]["accept"] == "t"
      unless retweet_status = connection.exec("SELECT tweet_status from tweet_info WHERE tweet_id = #{status.id}")
        connection.exec("UPDATE detect_per_user SET count=count+1 WHERE user_id = #{user.id}")
        result = connection.exec("SELECT count FROM detect_per_user WHERE user_id = #{user.id}")
        rest.update("#{user.name}(@#{user.screen_name})が#{result[0]["count"]}回目のツイ消しを行いました。【#{Time.now.to_s}】") if user.id != 817254158839332865
      end
    else
      # puts("accept is false")
    end
  when Twitter::Streaming::Event then
    if status.name == :follow
      rest.follow(status.source.id) if status.source.id != myinfo.id
    end
  # else
  #   # デバッグ用
  #   p status
  end
end

# close db connection
connection.finish if connection
