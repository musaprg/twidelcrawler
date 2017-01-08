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

stream.user do |status|
  case status
  when Twitter::Tweet then
    username = status.user.screen_name
    contents = status.text
    #リプライの場合
    if (contents.match(/^@#{myinfo.screen_name}\s*$/))
      if(contents.match(/やめて/))
        # 監視するのをやめる
        rest.update("@#{status.screen_name} 解除したよ。")
        connection.exec("UPDATE detect_per_user SET boolean = 0 WHERE user_id = #{status.user.id}")
      end
      if(constents.match(/みてて/))
        # 監視する
        rest.update("@#{status.screen_name} いつも見てるよ。")
        connection.exec("UPDATE detect_per_user SET boolean = 1 WHERE user_id = #{status.user.id}")
      end
    end
    str = username + ":" + contents
    puts str
  when Twitter::Streaming::DeletedTweet then
    user = rest.user(status.user_id)
    dbdata = connection.exec("SELECT * FROM detect_per_user WHERE user_id = #{user.id}")
    if dbdata.ntuples == 0
      connection.exec("INSERT INTO detect_per_user (user_id) VALUES (#{user.id})")
    end
    connection.exec("UPDATE detect_per_user SET count=count+1 WHERE user_id = #{user.id}")
    result = connection.exec("SELECT count FROM detect_per_user WHERE user_id = #{user.id}")
    rest.update("【#{Time.now.to_s}】#{user.name}(@#{user.screen_name})が#{result[0]["count"]}回目のツイ消しを行いました。") if user.id != 817254158839332865
  end
end

# close db connection
connection.finish if @connection
