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
      stub(actor).make_sub { sub }
      stub(actor).make_pub { local_pub }
    end
    it "должен зарегистрировать себя" do
      mock(Zactor).register actor
      actor.init
    end
    
    it "должен создать sub сокет" do
      mock(actor).make_sub { sub }
      actor.init
      actor.instance_eval { @sub }.should eq(sub)
    end
    
    it "должен создать pub сокет для локальных вызовов" do
      mock(actor).make_pub("inproc://zactor_broker_sub") { local_pub }      
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
      include Zactor::ZMQMEssages
      
      def assert_messages(got, expected)
        got.map(&:copy_out_string).should eq(expected.map(&:copy_out_string))
      end
      
      before do
        actor.init
      end
      describe "send_to" do
        it "должен отправить в локальный pub для локального объекта" do
          mes = messages { |m|  }
          stub(local_pub).send_messages do |mes|
            assert_messages mes, messages { |m|
              m.str('b')
              m.str(actor.bson_actor)
            }
          end
          actor.send_to Zactor.get_actor('b')
        end
        
        it "должен отправить в удаленный pub для удаленного объекта, перед этим создав его" do
          remote_pub = Object.new
          mock(actor).make_pub("tcp://192.168.1.1:3000") { remote_pub }
          stub(remote_pub).send_messages do |mes|
            assert_messages mes, messages { |m| m.str('b'); m.str(actor.bson_actor) }
          end
          actor.send_to Zactor.get_actor('b', :host => '192.168.1.1:3000')
        end
      end

      describe "send_request" do
        it "должен отправлять сообщение типа request" do
          stub(local_pub).send_messages do |mes|
            assert_messages mes, messages { |m| 
              m.str('b')
              m.str(actor.bson_actor)

              m.str 'request'
              m.str ""
              m.str "show"
              m.str BSON.serialize({ 'args' => ['foo', :bar] })
            }
          end
          actor.send_request Zactor.get_actor('b'), :show, 'foo', :bar
        end
      end

      describe "send_reply" do
        it "должен отправлять сообщение типа reply" do
          stub(local_pub).send_messages do |mes|
            assert_messages mes, messages { |m| 
              m.str('b')
              m.str(actor.bson_actor)

              m.str 'reply'
              m.str 5
              m.str BSON.serialize({ 'args' => ['foo', :bar] })
            }
          end
          actor.send_reply Zactor.get_actor('b'), 5, 'foo', :bar
        end
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