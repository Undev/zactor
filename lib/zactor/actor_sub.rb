module Zactor
  class ActorSub
    attr_accessor :actor
    def initialize(actor)
      Zactor.logger.debug "ZactorSub (#{actor.actor}): starting"
      @actor = actor
      @connection = Zactor.zmq.connect ZMQ::SUB, "inproc://zactor_broker_pub", self
      @connection.subscribe actor.actor['identity']
    end
    
    def on_readable(socket, messages)
      @connection.notify_readable = true
      Zactor.logger.debug "ZactorSub for #{actor.actor}: Messages!"
      to = messages.shift
      sender = messages.shift
      case messages.shift.copy_out_string
      when "reply"
        reply messages
      when "request"
        request sender, messages
      end      
    end
    
    def request(sender_mes, messages)
      Zactor.logger.debug "ZactorSub for #{actor.actor}: request!"
      sender = BSON.deserialize(sender_mes.copy_out_string)
      callback_id = messages[0].copy_out_string
      event = messages[1].copy_out_string
      args = BSON.deserialize(messages[2].copy_out_string)['args']      
      actor.receive_request sender, event, callback_id, *args
    end
    
    def reply(messages)
      Zactor.logger.debug "ZactorSub for #{actor.actor}: reply!"
      callback_id = messages[0].copy_out_string
      if callback_id != ''
        actor.receive_reply callback_id, *BSON.deserialize(messages[1].copy_out_string)['args']
      end
    end
    
    def close
       @connection.unbind
    rescue
    end
  end 
end