# -*- coding: utf-8 -*-
require 'ruby_interface'
require 'active_support/all'
require 'ffi-rzmq'
require 'em-zeromq'
require 'bson'

# Что это
# =======
# Zactor позволяет любой руби-объект научить общаться с другими объектами посредством отправки и получения сообщений. При этом неважно где именно расположен объект, в том же процессе, в соседнем, или на другой физической машине.
# 
# Zactor использует zmq как бекенд для сообщений, eventmachine и em-zeromq для асинхронной работы с zmq, RubyInterface для описания себя, BSON для сериализации данных.
# 
# Каждый zactor-объект имеет свой identity, который генерируется автоматически, либо задается вручную и постоянен. Совокупность identity, host и port на которых был рожден этот объект, это достаточная информация для того что бы отправить этому объекту сообщение из другого объекта. Выглядит примерно так:
#    
#         zactor.actor =>
#         {"identity"=>"actor.2154247120-0.0.0.0:8000", "host"=>"0.0.0.0:8000"}
#   
# Ипользование
# ============
# 
# Для начала нужно стартануть Zactor.
#   
#     Zactor.start 8000
#   
# Процесс забиндится на 0.0.0.0:8000, через эту точку будет происходить общение между zactor-процессами. Стартоваться должен в запущенном EM-контексте.
# 
# В каждый zactor-активный класс нужно делать include Zactor, после чего у класса и его экземпляров для доступа к функциями Zactor появится метод zactor. После создания объекта нужно выполнить zactor.init
# 
#     class A
#       include Zactor
#   
#       def initialize
#         zactor.init
#       end
#     end
#   
# Для отправки сообщений другому объекту нам нужно знать его идентификатор. Идентификатор можно получить тремя способами:
# 
# * Непосрдественной передачей. При инициализации или в любом другом месте, это исключительно внутренняя логика приложения. Идентификатор объекта можно получить вызвав zactor.actor
# * При получении сообщения. В сообщении всегда содержится информация об отправителе
# * Если объект имеет заранее известный identity, то мы можем получить его полный идентификатор вызвав Zactor.get_actor с identity и хостом, на котором он запущен
#   
#     actor = Zactor.get_actor "broker", :host => "0.0.0.0:8001"
#   
# Получив идентификатор можно отправлять ему сообщения
#   
#     zactor.send_request actor, :show_me, :boobs
# 
#   
# Каждый класс может определять какие именно ивенты он может получать и что с ними делать
#  
#     include Zactor
# 
#     zactor do
#       event(:show_me) do |o, msg, what|
#         case what
#         when :boobs
#           do_it
#         else
#           do_smth_else
#         end
#       end
#     end
#   
# Рассмотрим пример банального ping-pong
# 
#     class A
#       include Zactor
# 
#       def initialize
#         zactor.init
#         ping Zactor.get_actor("b")
#       end
#   
#       def ping(actor) 
#         puts "Ping!"
#         zactor.send_request actor, :ping do |res|
#           puts res
#         end
#       end
#     end
# 
# 
#     class B
#       include Zactor
#   
#       zactor do
#         identity "b"
#     
#         event(:ping) do |o, msg|
#           msg.reply "Pong!"
#         end
#       end
#   
#       def initialize
#         zactor.init
#       end
# 
#     end
# 
#     EM.run do
#       Zactor.start 8000
#   
#       a = A.new
#       b = B.new
#     end
#   
# A посылает сообщение :ping для B, а B отвечает "Pong!"
# 
# В коллбэк определенный в event передается объект получившый сообщение, объект сообщения ({Zactor::Message}) и далее переданные в запросе аргументы (если они есть). У {Zactor::Message} есть два основных метода: sender, возвращающий идентификатор отправителя и reply, который посылает ответ на запрос.
# 
# Важный момент, identity должно задаваться ДО zactor.init и после этого не может меняться.
# 
# ZMQ
# ===
# 
# При Zactor.start стартует брокер, по одному на каждый процесс, через него проходят все сообщения данного процесса, принимает сообщения через SUB-сокет, отправляет через PUB. SUB подписан на все сообщения. Каждый zactor-объект создает по паре сокетов, PUB подключается к SUB-брокера, а SUB к PUB-брокера. SUB подписывается на сообщения содержащие его identity.
# 
# ![ZMQ](zactor/images/zmq1.png)
# 
# Рассмотрим жизнь сообщения на примере с ping-ping. В случае с b в том же процессе:
# 
# <div class=wsd wsd_style="default"><pre>
# A[PUB]->Broker[SUB]: Посылаем запрос :ping
# Broker[SUB]->Broker[PUB]: Перебрасываем запрос в PUB сокет
# Broker[PUB]->B[SUB]: Передаем получателю сообщение
# B[PUB]->Broker[SUB]: Отправляем ответ "Pong!"
# Broker[SUB]->Broker[PUB]: Перебрасываем запрос в PUB сокет
# Broker[PUB]->A[SUB]: Отправитель получает ответ
# </pre></div><script type="text/javascript" src="http://www.websequencediagrams.com/service.js"></script>
# 
# В случае с b в другом процессе:
# 
# <div class=wsd wsd_style="default"><pre>
# A[PUB for App2]->App2 Broker[SUB]: Посылаем запрос :ping
# App2 Broker[SUB]->App2 Broker[PUB]: Перебрасываем запрос в PUB сокет
# App2 Broker[PUB]->B[SUB]: Передаем получателю сообщение
# B[PUB for App1]->App1 Broker[SUB]: Отправляем ответ "Pong!"
# App1 Broker[SUB]->App1 Broker[PUB]: Перебрасываем запрос в PUB сокет
# App1 Broker[PUB]->A[SUB]: Отправитель получает ответ
# </pre></div><script type="text/javascript" src="http://www.websequencediagrams.com/service.js"></script>
# 
# Балансировка
# ============
# 
# Так как это ZMQ, мы можем очень просто изменить тип получения сообщения. Например, добавив балансер. Теперь можно запускать процессы со ссылкой на этот балансер.
# 
#     Zactor.start :balancer => "0.0.0.0:4000"
#     
# У нас получится примерно следующая схема:
# 
# ![ZMQ](zactor/images/zmq2.png)
# 
# Теперь наш ping можно отправлять в балансер, а отвечать будет один из подключенных воркеров.
# 
#     ping Zactor.get_actor("b", :host => "0.0.0.0:4000")
#     
# 
# Протокол обмена
# ===============
# 
# 
# Perfomance
# ==========
# 
# А хрен его знает, толком не мерялось ничего :)
# 
# TODO
# ====
# 
# * Сделать событие отваливания объектов. Наверное, что-то вроде простого аналога link в эрланге.
# * Добавить таймауты для запросов с коллбэками. Сейчас они будут висеть бесконечно и засрут память.
# * Доступ к отправителю в колллбэке запроса. В случае с балансировкой он будет не тем же, кому мы посылали сообщение
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