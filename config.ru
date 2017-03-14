require 'rubygems'
require 'bundler'
require 'json'

Bundler.require

require './demo'

use Rack::Session::Cookie, :key => 'demo', :path => '/', :secret => 'secret'

run Demo
