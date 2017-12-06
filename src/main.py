#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import configparser
import MeCab
import tweepy
from db import session, Tweet, User

config = configparser.ConfigParser()
config.read('../config/conf.ini')

class StreamListener(tweepy.StreamListener):
    def __init__(self, api):
        super().__init__(api)
        self.me = self.api.me()

        for follow_id in tweepy.Cursor(api.friends_ids, user_id=self.me.id).items():
            if len(session.query(User).filter_by(uid=int(follow_id)).all()) == 0:
                new_record = User(uid=int(follow_id))

    def on_status(self, status):
        if status.author.id != self.me.id:
            print("{0} has been recorded.".format(status.id))
            new_record = Tweet(tid=int(status.id), uid=int(status.author.id), content=status.text, is_deleted=False)
            session.add(new_record)
            session.commit

    def on_delete(self, status_id, user_id):
        print("hoge")



if __name__ == "__main__":
    auth = tweepy.OAuthHandler(config["twitter"]["consumer_key"], config["twitter"]["consumer_secret"])
    auth.set_access_token(config["twitter"]["access_token"], config["twitter"]["access_token_secret"])
    api = tweepy.API(auth)

    stream = tweepy.Stream(auth = api.auth, listener=StreamListener(api))
    stream.userstream(async=True)