# -*- coding: utf-8 -*-

require 'spec_helper'
require "em-spec/rspec"

describe "Zactor" do
  include EM::SpecHelper
  module Link
    class A
      include Zactor

      def initialize
        zactor.init
      end
    end

    class B
      include Zactor

      def initialize
        zactor.init
      end
    end
  end
  
  after do
    puts "FINISH ZACTOR"
    Zactor.finish
  end
  
  it "A должен уведомляться о смерти B" do
    em do
      Zactor.start 8000, :debug => true
      a = Link::A.new
      b = Link::B.new
      a.zactor.link b.zactor.actor do
        done
      end
      EM.add_timer(0.5) do
        b.zactor.finish
      end
    end
  end
  
  # it "A должен уведомляться о смерти B в случае удаления объекта гарбэйдж коллектором" do
  #   
  # end
  
  it "A должен уведомляться о смерти B, даже если B закончил выполнение неожиданно" do    
    em(12) do
      EM.add_timer(0.5) do #FIXME ZMQ-сокетам нужно время чтобы закрыться. Нужно придумать, что с этим делать
        Zactor.start 8000, :debug => true
        a = Link::A.new
        b = Link::B.new
        a.zactor.link b.zactor.actor do
          done
        end
        EM.add_timer(0.5) do
          b.zactor.instance_eval do
            @linked = []
          end
          b.zactor.finish
        end
      end
    end
  end
end