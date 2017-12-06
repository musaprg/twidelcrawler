
import configparser
from sqlalchemy import create_engine, MetaData, Table, Column, Integer, String, Boolean, ForeignKey
from sqlalchemy.orm.session import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relation

config = configparser.ConfigParser()
config.read('../config/conf.ini')

Base = declarative_base()

# テーブルの作成
class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)
    uid = Column(Integer, unique=True)
    count = Column(Integer, default=0, nullable=False)
    is_accepted = Column(Boolean, default=True, nullable=False)

    tweets = relation('Tweet', order_by='Tweet.id', uselist=True, backref='users')

class Tweet(Base):
    __tablename__ = 'tweets'

    id = Column(Integer, primary_key=True)
    uid = Column(Integer, ForeignKey('users.uid'))
    tid = Column(Integer, nullable=False)
    content = Column(String, nullable=False)
    is_deleted = Column(Boolean, default=False, nullable=False)

engine = create_engine('sqlite:///db.sqlite3', echo=True)
Base.metadata.create_all(engine)
SessionMaker = sessionmaker(bind=engine)
session = SessionMaker()