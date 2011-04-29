# -*- coding: utf-8 -*-

# ruby server.rb PORT
# ruby server.rb 8000
require 'bundler'
ENV['BUNDLE_GEMFILE'] = File.join(File.dirname(__FILE__), '..', '..', 'Gemfile')
Bundler.setup(:default)

require 'zactor'

class Server
  include Zactor
  
  zactor do
    identity "server"
    
    event(:new_client) do |o, msg, login|
      o.new_client msg.sender, login
      msg.reply :ok
    end
    
    event(:client_request) do |o, msg, login|
      if client = o.clients.detect { |k, v| v == login }
        msg.reply :ok, client.first
      else
        msg.reply :error
      end
    end
    
    event(:message) do |o, msg, text|
      o.send_message msg.sender, text
    end
  end
  
  attr_accessor :clients
  def initialize
    zactor.init
    @clients = {}
  end
  
  def new_client(client, login)
    @clients[client] = login
    send_message client, "присоединился"
    zactor.link client do
      send_message client, "отсоединился"
      clients.delete client
    end
  end
  
  def send_message(from, message)
    (clients.keys - [from]).each { |c| zactor.send_request c, :message, "#{clients[from]}: #{message}"}
  end
end

EM.run do
  Zactor.start ARGV[0]#, :debug => true
  Server.new
  puts "Server started"
end