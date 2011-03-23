module Zactor
  class Message
    attr_accessor :actor, :params
    attr_accessor :callback_id, :args
    def initialize(actor, params = {})
      @actor = actor
      @params = params
    end
    
    def sender
      params[:sender]
    end
    
    def args
      params[:args]
    end
    
    def reply(*args)
      return false unless params[:callback_id]
      actor.send_reply sender, params[:callback_id], *args
    end
  end
end