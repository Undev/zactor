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
      @broker.pub.request messages
    end
  end
  
  class BrokerPub
    include ZMQMEssages
    def initialize(broker)
      @broker = broker
      @connection = Zactor.zmq.bind ZMQ::PUB, "inproc://zactor_broker_pub", self
      @socket = @connection.socket
    end
    
    def request(messages)
      Zactor.logger.debug "Broker: request"
      send_messages messages
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
      @pub = BrokerPub.new self
      BrokerSub.new self
      BrokerPull.new self, :host => params[:balancer] if params[:balancer]
    end
  end
end