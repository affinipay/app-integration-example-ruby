require 'rubygems'
require 'bundler'
require 'json'

Bundler.require

require './app/demoApi'

use Rack::Session::Cookie, :key => 'demo', :path => '/', :secret => 'secret'

# run Demo
run DemoApi
