# -*- coding: utf-8 -*-
require 'ruby_interface'
require 'active_support/all'
require 'ffi-rzmq'
require 'em-zeromq'
require 'bson'

module Zactor
  extend ActiveSupport::Autoload

  autoload :Broker
  autoload :ActorSub
  autoload :ActorPub
  autoload :Message
  require 'zactor/log_subscriber'

  mattr_accessor :stub
  mattr_accessor :zmq, :logger
  
  class << self    
    def broker
      @broker
    end
    
    def broker_port
      @broker_port
    end
    
    def host
      @host
    end
    
    def start(broker_port, params = {})
      self.zmq ||= EM::ZeroMQ::Context.new(1)
      self.logger ||= Logger.new(STDOUT).tap { |o| o.level = params[:debug] ? Logger::DEBUG : Logger::INFO }
      @host = "#{params.delete(:host) || '0.0.0.0'}:#{broker_port}"
      @broker_port = broker_port
      @params = params
      
      logger.info "Starting Zactor"
      @broker = Broker.new :balancer => params[:balancer]
    end
    
    def get_actor(pid, options = {})
      h = options[:host] || host
      { 'identity' => pid, 'host' => h }
    end
    
    def register(zactor)
      @zactors ||= {}
      @zactors[zactor] = true
    end
    
    def deregister(zactor)
      @zactors.delete zactor
      puts "ZACTORS: #{@zactors.size}"
    end
  end
  
  module ZMQMEssages
    class ZMQMessage
      attr_accessor :res
      def initialize(&blk)
        @res = []
        blk.call self
      end
      
      def str(str)
        @res << ZMQ::Message.new.tap { |o| o.copy_in_string str.to_s }
      end
      
      def mes(message)
        @res << message
      end
    end
    
    def send_messages(messages)
      last = messages[-1]
      messages[0...-1].each do |mes|
        sent = @socket.send mes, ZMQ::NOBLOCK | ZMQ::SNDMORE
        break unless sent
      end
      sent = @socket.send last, ZMQ::NOBLOCK
      unless sent
        Zactor.logger.info "[Zactor] Error while sending messages"
      end
    end
    
    def messages(&blk)
      ZMQMessage.new(&blk).res
    end
  end
  
  def self.interfaced(base)
    base.zactor do
      event(:finish) { |o| o.finish }
      event(:linked) do |o, msg, actor| 
        o.linked actor
        msk.reply :ok
      end
    end
  end
  
  extend RubyInterface
  interface :zactor do
    include ZMQMEssages
    
    class_attribute :identity_val
    class_attribute :events
    self.events = {}
    class << self
      def identity(val)
        self.identity_val = val
      end
      
      def event(name, &clb)
        self.events = self.events.merge name.to_sym => clb
      end
    end
    attr_accessor :actor, :identity
    attr_accessor :pubs
    def init
      @actor = Zactor.get_actor @identity || self.class.identity_val || "actor.#{owner.object_id}-#{Zactor.host}"
      Zactor.register self
      return if Zactor.stub
      @sub = Zactor::ActorSub.new self
      @callbacks = {}
      @pubs = {}
      @pubs["0.0.0.0:#{Zactor.broker_port}"] = Zactor::ActorPub.new self, "inproc://zactor_broker_sub"
    end
    
    def finish
      Zactor.deregister self
      return if Zactor.stub
      @finished = true
      @sub.close
      @pubs.values.each(&:close)
    end
    
    def send_request(actor, event, *args, &clb)
      return if @finished || Zactor.stub
      ActiveSupport::Notifications.instrument('send_request.zactor', :event => event, :actor => actor, :params => args) do
        @callbacks[clb.object_id.to_s] = clb if clb
        send_to actor, messages { |m|
          m.str 'request'
          m.str "#{clb ? clb.object_id : ''}"
          m.str event
          m.str BSON.serialize({ 'args' => args })
        }
      end
    end
    
    def send_reply(actor, callback_id, *args)
      return if @finished || Zactor.stub
      Zactor.logger.debug "Zactor: send reply"
      send_to actor, messages { |m|
        m.str 'reply'
        m.str callback_id
        m.str BSON.serialize({ 'args' => args })
      }
    end
    
    def send_to(actor, mes)
      ActiveSupport::Notifications.instrument('send_to.zactor', :actor => actor) do
        pub = @pubs[actor['host']] ||= Zactor::ActorPub.new(self, "tcp://#{actor['host']}")
        pub.send_messages(messages { |m|
          m.str actor['identity']
          m.str bson_actor
        } + mes)
      end
    end
    
    def link(actor)
      
    end
    
    def receive_reply(callback_id, *args)
      Zactor.logger.debug "Zactor: receive reply"
      if (callback = @callbacks[callback_id])
        callback.call(*args)
      end
    end
    
    def receive_request(sender, event_name, callback_id, *args)
      Zactor.logger.debug "Zactor: receive request"
      mes = Message.new self, :sender => sender, :callback_id => callback_id, :args => args
      if (event = self.class.events[event_name.to_sym])
         event.call owner, mes, *args
       else
         raise "Undefined event #{event_name}"
       end
    end
    
    def bson_actor
      @bson_actor ||= BSON.serialize(@actor).to_s
    end

    
    def inspect
      "<#Zactor Interface for #{owner.inspect}"
    end

  end
  
end