# encoding: utf-8

require 'pg'
# require 'yaml'
require 'twitter'
# require 'net/https'
# require 'oauth'
# require 'cgi'
# require 'json'

# twconf = YAML.load_file("config.yml")["twitter"]
# dbconf = YAML.load_file("config.yml")["db"]["product"]
dbconf = {
  dbname: "mrmita_tweetinfo",
  port: 5432
}

config = {
  consumer_key: ENV['MITA_CK'],
  consumer_secret: ENV['MITA_CS'],
  access_token: ENV['MITA_AT'],
  access_token_secret: ENV['MITA_ATS']
}

p config

rest = Twitter::REST::Client.new(config)
stream = Twitter::Streaming::Client.new(config)

# verify_credentials = rest.verify_credentials
# myinfo = rest.user(verify_credentials.id)

# puts("Bot's screen_name is \"#{myinfo.screen_name}\"")

puts("Initialize DB Connection")

# initialize db connection
connection = PG::connect(dbconf)
is_table = connection.exec("SELECT relname FROM pg_class WHERE relkind = 'r' AND relname = 'detect_per_user'")
if is_table.ntuples == 0
  connection.exec("CREATE TABLE detect_per_user (\
    id        serial    PRIMARY KEY,\
    user_id   int8,\
    count     int8      DEFAULT '0',\
    accept    boolean   DEFAULT '1'\
  );")

  # 削除済のツイートの詳細を確認することは出来ないのでTwitter::Tweetオブジェクトが降ってきた場合に
  # ステータスを格納するテーブルを作成した。Twitter::Streaming::DeletedTweetオブジェクトが降ってきた
  # 場合にこのテーブルから詳細データを取り出してやり、falseの場合のみツイ消しと判定するようにした。

  connection.exec("CREATE TABLE tweet_info (\
    id        serial    PRIMARY KEY,\
    tweet_id int8,\
    tweet_status boolean,\
  );")
end



puts("DB connection established")

puts("Start Crawling...")

stream.user do |status|
  case status
  when Twitter::Tweet then
    username = status.user.screen_name
    contents = status.text
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
