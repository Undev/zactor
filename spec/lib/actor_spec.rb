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

    it "должен зарегистрировать себя" do
      mock(Zactor).register actor
      actor.init
    end
    
    describe "identity" do
      
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
      
      def remote_pub(actor)
        Zactor.pub(actor)
      end
      
      before do
        actor.init
        Zactor.instance_eval { @pubs['192.168.1.1:3000'] = Object.new }
      end
      
      
      describe "send_to" do
        it "должен отправить в локальный pub для локального объекта" do
          remote_actor = Zactor.get_actor('b', :host => '192.168.1.1:3000')
          mes = messages { |m|  }
          stub(remote_pub(remote_actor)).send_messages do |mes|
            assert_messages mes, messages { |m|
              m.str('b')
              m.str(actor.bson_actor)
            }
          end
          actor.send_to remote_actor
        end
        
        it "должен отправить в удаленный pub для удаленного объекта, перед этим создав его" do
          remote_actor = Zactor.get_actor('b', :host => '192.168.1.1:3000')
          stub(remote_pub(remote_actor)).send_messages do |mes|
            assert_messages mes, messages { |m| m.str('b'); m.str(actor.bson_actor) }
          end
          actor.send_to remote_actor
        end
      end

      describe "send_request" do
        it "должен отправлять сообщение типа request" do
          remote_actor = Zactor.get_actor('b', :host => '192.168.1.1:3000')
          stub(remote_pub(remote_actor)).send_messages do |mes|
            assert_messages mes, messages { |m| 
              m.str('b')
              m.str(actor.bson_actor)
      
              m.str 'request'
              m.str ""
              m.str "show"
              m.str BSON.serialize({ 'args' => ['foo', :bar] })
            }
          end
          actor.send_request remote_actor, :show, 'foo', :bar
        end
      end
      
      describe "send_reply" do
        it "должен отправлять сообщение типа reply" do
          remote_actor = Zactor.get_actor('b', :host => '192.168.1.1:3000')
          stub(remote_pub(remote_actor)).send_messages do |mes|
            assert_messages mes, messages { |m| 
              m.str('b')
              m.str(actor.bson_actor)
      
              m.str 'reply'
              m.str 5
              m.str BSON.serialize({ 'args' => ['foo', :bar] })
            }
          end
          actor.send_reply remote_actor, 5, 'foo', :bar
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