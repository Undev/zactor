module Zactor
  class ActorPub
    include ZMQMEssages
    
    attr_accessor :actor
    def initialize(endpoint)
      Zactor.logger.debug "ZactorPub (#{endpoint}): starting"
      @connection = Zactor.zmq.connect ZMQ::PUB, endpoint, self
      @socket = @connection.socket
    end
    
    def close
      @connection.unbind
    rescue
    end
  end
 
end