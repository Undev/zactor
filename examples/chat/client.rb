# -*- coding: utf-8 -*-

# ruby client.rb SELF_PORT SERVER LOGIN
# ruby client.rb 6001 0.0.0.0:8000 lolo
require 'bundler'
ENV['BUNDLE_GEMFILE'] = File.join(File.dirname(__FILE__), '..', '..', 'Gemfile')

Bundler.setup(:default)

require 'zactor'
class Client
  include Zactor
  
  zactor do
    event(:message) do |o, msg, text|
      puts text
    end
  end
  
  def initialize(login)
    @login = login
    @persons = {}
  end
  
  def start(server)
    zactor.init 
    @server = Zactor.get_actor("server", :host => server)
    connect
  end
  
  def connect
    puts "Подключаемся"
    zactor.send_request(@server, :new_client, @login) do
      puts "Поключились!"
      zactor.link(@server) { connect }
    end.timeout(5) { puts "Проблемы с подключением..." }
  end
  
  def send_message(text)
    if text =~ /(\w+) -> (.+)/
      send_personal($1, $2)
    else
      zactor.send_request(@server, :message, text)
    end
  end
  
  def send_personal(login, text)
    if client = @persons[login]
      zactor.send_request(client, :message, "(personally) #{@login}:" + "#{text}")
    else
      zactor.send_request(@server, :client_request, login) do |res, client|
        case res
        when :ok
          @persons[login] = client
          zactor.link(client) { @persons.delete login }
          zactor.send_request(client, :message, "(personally) #{@login}:" + "#{text}")
        else
          puts "Ошибка отправки сообщения"
        end
      end
    end
  end
  
  def stop
    zactor.finish
    EM.stop
  end
  
  module KeyboardInput
    include EM::Protocols::LineText2
    attr_accessor :client
    def receive_line(data)
      client.send_message data
    end
  end
   
end

client = Client.new ARGV[2]

Signal.trap('INT') { client.stop } 
Signal.trap('TERM') { client.stop }

EM.run do
  Zactor.start ARGV[0]#, :debug => true
  client.start ARGV[1]
  EM.open_keyboard(Client::KeyboardInput) { |c| c.client = client }
end
