# -*- coding: utf-8 -*-

require 'spec_helper'
require "em-spec/rspec"

describe "Zactor" do
  include EM::SpecHelper
  module Exchange
    class A
      include Zactor

      def initialize
        zactor.init
      end

      def ping(actor = Zactor.get_actor("b")) 
        zactor.send_request actor, :ping do |res|
          require 'ruby-debug'
          debugger if $t
          reply
        end
      end
      
      def reply
        
      end
    end

    class B
      include Zactor

      zactor do
        identity "b"

        event(:ping) do |o, msg|
          o.receive
          msg.reply "Pong!"
        end
      end

      def initialize
        zactor.init
      end

      def receive
        
      end
    end
  end
  
  def em_start(timeout = 5, &blk)
    em(timeout) do
      Zactor.start 8000, :debug => true
      blk.call
    end
  end
  
  
  def em_done
    Zactor.clear
    Zactor.finish
    EM.add_timer(0.1) { done }
  end
  
  it "B должен получить сообщение" do
    em_start do
      a = Exchange::A.new
      b = Exchange::B.new
      mock.proxy(b).receive { em_done }
      a.ping
      
    end
  end
  
  it "A должен получить ответ" do
    em_start do
      a = Exchange::A.new
      Exchange::B.new
      mock.proxy(a).reply { em_done }
      a.ping
    end
  end
  
  it "Если задан таймаут, то он должен срабатывать" do
    em_start(7) do
      a = Exchange::A.new.ping.timeout(5) do
        em_done
      end
    end
  end
end