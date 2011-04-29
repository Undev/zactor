require "rubygems"
require "bundler"

ENV['BUNDLE_GEMFILE'] = File.join(File.dirname(__FILE__), '..', '..', 'Gemfile')

Bundler.setup(:default, :development)

require 'zactor'
require 'eventmachine'

class A
  include Zactor

  def initialize
    zactor.init
    ping Zactor.get_actor("b")
  end

  def ping(actor) 
    puts "Ping!"
    zactor.send_request actor, :ping do |res|
      puts res
    end
  end
end


class B
  include Zactor

  zactor do
    identity "b"
  
    event(:ping) do |o, msg|
      msg.reply "Pong!"
    end
  end

  def initialize
    zactor.init
  end

end

EM.run do
  Zactor.start 8000

  a = A.new
  b = B.new
end