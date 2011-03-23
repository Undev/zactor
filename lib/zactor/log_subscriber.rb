# -*- coding: utf-8 -*-
require 'active_support/log_subscriber'
module Zactor
  class LogSubscriber < ActiveSupport::LogSubscriber
    def logger
      Zactor.logger
    end

    def merge(event)
      payload   = event.payload

      message = "[Zactor](%.0fms) sending request '#{payload[:event]}' to '#{payload[:actor]}'' with params #{paylaod[:args].inspect}" % event.duration
      debug message
    end

    def send_to(event)
      payload   = event.payload

      message = "[Zactor] sending messages to '#{payload[:actor]}'" % event.duration
      debug message
    end
  end
end

Zactor::LogSubscriber.attach_to :zactor
