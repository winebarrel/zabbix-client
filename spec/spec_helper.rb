$: << File.expand_path('..', __FILE__)
require 'zabbix/client'
require 'json'
require 'webrick'
require 'webrick/httpproxy'
require 'webrick/https'

trap(:INT) do
  $zabbix_server.shutdown if $zabbix_server
end

RSpec.configure do |config|
  config.after(:each) do
    if $zabbix_server
      shutdown_server($zabbix_server)
    end
  end
end

def start_server(server)
  Thread.start do
    server.start
  end

  sleep 0.1 until server.status == :Running
end

def shutdown_server(server)
  server.shutdown
  sleep 0.1 until server.status == :Stop
end

def default_handler
  proc do |req, res|
    res.body = JSON.dump(:result => {
      :body => req.body,
      :header => req.header,
    })
  end
end

def run_client(options = {})
  options = {:handler => default_handler}.merge(options)

  server_opts = {
    :Port => 20080,
    :Logger => WEBrick::Log.new('/dev/null'),
    :AccessLog => []
  }

  if user_pass = options.delete(:basic_auth)
    server_opts[:RequestCallback] = proc do |req, res|
      WEBrick::HTTPAuth.basic_auth(req, res, "my realm") do |username, password|
        [username, password] == user_pass
      end
    end
  end

  if ssl = options.delete(:ssl)
    server_opts[:SSLEnable] = true
    server_opts[:SSLCertName] = [['CN', WEBrick::Utils::getservername]]
  end

  $zabbix_server = WEBrick::HTTPServer.new(server_opts)

  $zabbix_server.mount_proc('/', &options.delete(:handler))
  start_server($zabbix_server)

  url = (ssl ? 'https' : 'http') + '://localhost:20080'
  client = Zabbix::Client.new(url, options)
  yield(client)
end

def proxy
  begin
    server = WEBrick::HTTPProxyServer.new(
      :Port => 30080,
      :Logger => WEBrick::Log.new('/dev/null'),
      :AccessLog => [])

    start_server(server)

    yield('localhost', 30080)
  ensure
    shutdown_server(server) if server
  end
end
