# -*- coding: utf-8 -*-

import configparser

config = configparser.ConfigParser()

config["twitter"] = {
    "consumer_key": "hoge",
    "consumer_secret": "hoge",
    "access_token": "hoge",
    "access_token_secret": "hoge"
}

# settings for mysql or postgresql
config["db"] = {
    "host": "localhost",
    "user": "root",
    "password": "root",
    "dbname": "postgres",
    "port": 5432
}

with open("conf.ini", "w") as f:
    config.write(f)
