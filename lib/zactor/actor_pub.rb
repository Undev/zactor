module Zactor
  class ActorPub
    include ZMQMEssages
    
    attr_accessor :actor
    def initialize(actor, endpoint)
      Zactor.logger.debug "ZactorPub (#{actor.actor}): starting"
      @actor = actor
      @connection = Zactor.zmq.connect ZMQ::PUB, endpoint, self
      @socket = @connection.socket
    end
    
    def close
      @connection.unbind
    rescue
    end
  end
 
end