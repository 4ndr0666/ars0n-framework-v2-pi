FROM ruby:3.2-alpine

RUN apk add --no-cache ruby-dev build-base

RUN gem install cewl

ENTRYPOINT ["cewl"]