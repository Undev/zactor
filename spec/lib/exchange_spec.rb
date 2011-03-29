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
  
  after do
    Zactor.clear
    Zactor.finish
  end
  
  it "B должен получить сообщение" do
    em do
      Zactor.start 8000, :debug => true
      Exchange::A.new.ping
      b = Exchange::B.new
      mock.proxy(b).receive { done }
    end
  end
  
  it "A должен получить ответ" do
    em do
      Zactor.start 8000, :debug => true
      a = Exchange::A.new
      a.ping
      Exchange::B.new
      mock.proxy(a).reply { done }
    end
  end
  
  it "Если задан таймаут, то он должен срабатывать" do
    em(7) do
      Zactor.start 8000, :debug => true
      a = Exchange::A.new.ping.timeout(5) do
        done
      end
    end
  end
end