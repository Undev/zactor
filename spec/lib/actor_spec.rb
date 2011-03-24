# -*- coding: utf-8 -*-

require 'spec_helper'

describe "Zactor actor" do
  class A
    include Zactor
  end
  before do
    stub(Zactor::Broker).new
    Zactor.start 8000
  end
  describe "init" do
    let(:actor) { A.new.zactor }
    let(:sub) { Object.new }
    let(:local_pub) { Object.new }
    before do
      stub(Zactor::ActorSub).new { sub }
      stub(Zactor::ActorPub).new { local_pub }
    end
    it "должен зарегистрировать себя" do
      mock(Zactor).register actor
      actor.init
    end
    
    it "должен создать sub сокет" do
      mock(Zactor::ActorSub).new(actor) { sub }
      actor.init
      actor.instance_eval { @sub }.should eq(sub)
    end
    
    it "должен создать pub сокет для локальных вызовов" do
      mock(Zactor::ActorPub).new(actor, "inproc://zactor_broker_sub") { local_pub }
      actor.init      
      actor.instance_eval { @pubs['0.0.0.0:8000'] }.should eq(local_pub)
    end
    
    describe "identity" do
      it "по-умолчанию" do
        actor.init
        actor.actor.should eq({ 'identity' => "actor.#{actor.owner.object_id}-0.0.0.0:8000", 'host' => '0.0.0.0:8000' })
      end
      
      it "с глобальным указанием" do
        A.zactor.identity "a"
        actor.init
        actor.actor.should eq({ 'identity' => "a", 'host' => '0.0.0.0:8000' })
      end
      
      it "с указанием для этого объекта" do
        actor.identity = "b"
        actor.init
        actor.actor.should eq({ 'identity' => "b", 'host' => '0.0.0.0:8000' })
      end
    end
    
    describe "after init" do
      # include Zactor::ZMQMEssages
      # describe "send_to" do
      #   it "должен отправить в локальный pub для локального объекта" do
      #     mock(local_pub).send_messages(messages { str('b'); str(actor.bson_actor) })
      #     actor.send_to Zactor.get_actor('b', [])
      #   end
      # end

      describe "send_request" do

      end

      describe "send_reply" do

      end

      describe "receive_reply" do

      end

      describe "receive_request" do

      end

      describe "finish" do

      end
    end    

  end
end