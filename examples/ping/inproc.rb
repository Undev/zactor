require "rubygems"
require "bundler"

ENV['BUNDLE_GEMFILE'] = File.join(File.dirname(__FILE__), '..', '..', 'Gemfile')

Bundler.setup(:default, :development)

require 'zactor'
require 'eventmachine'

class A
  include Zactor

  def initialize
    @counter = 0
    zactor.init
  end
  
  def start
    ping Zactor.get_actor("b", :host => "0.0.0.0:#{ARGV[1]}")
  end

  def ping(actor)
    zactor.send_request actor, :ping do |res|
      @counter += 1
      if @counter % 1000 == 0
        puts @counter 
      end
      EM.next_tick { ping(actor) }
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
  
  Zactor.start ARGV[0]

  a = A.new
  b = B.new
  a.start
end