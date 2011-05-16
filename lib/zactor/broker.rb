module Zactor
  class BrokerIn
    attr_accessor :broker, :params 
    def initialize(broker, params = {})
      @broker = broker
      @params = params
      init_connection
    end
    
    def on_readable(socket, messages)
      Zactor.logger.debug "Broker: messages"
      @broker.dispatch_request messages
    end
    
    def close
       @connection.unbind
    rescue
    end
  end
  
  class BrokerSub < BrokerIn
    def init_connection
      Zactor.logger.info "Starting sub broker tcp://0.0.0.0:#{Zactor.broker_port}"
      @connection = Zactor.zmq.bind ZMQ::SUB, "tcp://0.0.0.0:#{Zactor.broker_port}", self
      @connection.bind "inproc://zactor_broker_sub"
      @connection.subscribe ''
    end
  end
  
  class BrokerPull < BrokerIn
    def init_connection
      Zactor.logger.info "Starting pull broker tcp://#{params[:host]}"
      @connection = Zactor.zmq.connect ZMQ::PULL, "tcp://#{params[:host]}", self
    end
  end
  
  class Broker
    attr_accessor :sub, :pub
    def initialize(params = {})
      Zactor.logger.info "Broker: starting"
      @subs = []
      @subs << BrokerSub.new(self)
      @subs << BrokerPull.new(self, :host => params[:balancer]) if params[:balancer]
    end
    
    def dispatch_request(messages)
      to = messages.shift.copy_out_string
      actor = Zactor.zactors[to]
      return unless actor
      Zactor.logger.debug "ZactorSub for #{actor.actor}: Messages!"
      sender = messages.shift
      case messages.shift.copy_out_string
      when "reply"
        reply actor, messages
      when "request"
        request actor, sender, messages
      end
    end
    
    def request(actor, sender_mes, messages)
      Zactor.logger.debug "ZactorSub for #{actor.actor}: request!"
      sender = BSON.deserialize(sender_mes.copy_out_string)
      callback_id = messages[0].copy_out_string
      event = messages[1].copy_out_string
      args = BSON.deserialize(messages[2].copy_out_string)['args']      
      actor.receive_request sender, event, callback_id, *args
    end
    
    def reply(actor, messages)
      Zactor.logger.debug "ZactorSub for #{actor.actor}: reply!"
      callback_id = messages[0].copy_out_string
      if callback_id != ''
        actor.receive_reply callback_id, *BSON.deserialize(messages[1].copy_out_string)['args']
      end
    end
    
    def finish
      @subs.each(&:close)
    end
  end
end