## capistrano-scrip

bunch of capistrano recipes

## Installation

Add `capistrano-scrip` to your application's Gemfile:

    gem 'capistrano-scrip', :git => 'git://github.com/glyuck/capistrano-scrip.git'

And then install the bundle:

    $ bundle

## Usage

First, initialize capistrano:

    capify .
    
This will create `./Capfile ` and `./config/deploy.rb`. Edit `./config/deploy.rb` and load recipes required
for your application:

    require "capistrano-scrip/nginx"
    require "capistrano-scrip/mysql"
    require "capistrano-scrip/host"

Then run `cap host:setup deploy:cold` to make your first deploy. Use `cap deploy:migrations` for next deploys.
