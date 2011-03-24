# -*- coding: utf-8 -*-

require 'spec_helper'

describe "Zactor" do
  describe "start" do
    before do
      stub(Zactor::Broker).new
    end
    it "должен выставлять хост по-умолчанию 0.0.0.0" do
      Zactor.start 8000
      Zactor.host.should eq('0.0.0.0:8000')
    end
    
    it "должен выставлять хост с учетом переданного" do
      Zactor.start 8000, :host => '192.168.1.1'
      Zactor.host.should eq('192.168.1.1:8000')
    end
    
    it "должен создавать новый брокер с указаным балансером" do
      mock(Zactor::Broker).new :balancer => '0.0.0.0:4000'
      Zactor.start 8000, :balancer => '0.0.0.0:4000'
    end
  end
  
  describe "get_actor" do
    before do
      stub(Zactor::Broker).new
      Zactor.start 8000
    end
    it "в качестве хоста по-умолчанию ставит себя же" do
      Zactor.get_actor("actor1").should eq({ 'identity' => 'actor1', 'host' => '0.0.0.0:8000' })
    end
    
    
    it "в качестве хоста ставит переданный" do
      Zactor.get_actor("actor1", :host => '192.168.1.1:3000').should eq({ 'identity' => 'actor1', 'host' => '192.168.1.1:3000' })
    end
  end
end
