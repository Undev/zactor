require "rubygems"
require "bundler"

ENV['BUNDLE_GEMFILE'] = File.join(File.dirname(__FILE__), '..', 'Gemfile')

Bundler.setup(:default, :development)

require 'zactor'
# require 'zactor_zmqmachine'
require 'eventmachine'



class B
  include Zactor
  
  zactor do
    identity "b"
    
    event(:ping) do |o, msg, counter|
      SFK.logger.info "Request2 #{counter}"
      msg.reply "Pong2 #{counter}!"
    end
  end
  
  def initialize
    zactor.init
  end
  
  def inspect
    "<#B>"
  end
end

EM.run do
  Zactor.start 8001, :debug => true
  
  b = B.new
  # EM.next_tick do
  # end
  
  # SFK.logger.info "CONNECTION!"
  # SFK.logger.info a.zactor.connects.values.first.connection.send :readable?
  # SFK.logger.info a.zactor.connects.values.first.connection.send :readable?
  # a.zactor.connects.values.first.connection.send :notify_readable
  # EM.add_timer(2) { a.ping }
  
end
