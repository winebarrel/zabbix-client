class Zabbix::Client
  DEFAULT_HEADERS = {
    'Content-Type' => 'application/json-rpc'
  }

  class Method
    JSON_RPC_VERSION = '2.0'
    JSON_RPC_REQUEST_ID = 1
    LOGIN_METHOD = 'user.login'

    def initialize(prefix, client)
      @prefix = prefix
      @client = client
    end

    def method_missing(method_name, *args, &block)
      validate_args(args)

      method   = "#{@prefix}.#{method_name}"
      params   = args[0] || []
      options  = args[1] || {}
      response = query(method, params, options)

      if (error = response['error'])
        error = error.merge('method' => method, 'params' => params, 'options' => options)
        raise Zabbix::Client::Error.new(error)
      end

      result = response['result']

      if method == LOGIN_METHOD
        @client.auth = result
      end

      if block
        block.call(result)
      else
        result
      end
    end

    private

    def query(method, params, options)
      body = {
        :jsonrpc => JSON_RPC_VERSION,
        :method  => method,
        :params  => params,
        :id      => JSON_RPC_REQUEST_ID,
      }.merge(options)

      body[:auth] = @client.auth if @client.auth
      body = JSON.dump(body)
      http = Net::HTTP.new(@client.url.host, @client.url.port)

      if @client.url.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      @client.http_hook.call(http) if @client.http_hook

      http.start do |h|
        response = h.post(@client.url.path, body, @client.headers)
        JSON.parse(response.body)
      end
    end

    def validate_args(args)
      unless (0..2).include?(args.length)
        raise ArgumentError, "wrong number of arguments: #{args.inspect} (#{args.length} for 0..2)"
      end

      args.each do |arg|
        unless arg.kind_of?(Hash)
          raise TypeError, "wrong argument: #{arg.inspect} (expected Hash)"
        end
      end
    end
  end # Method

  attr_reader   :url
  attr_reader   :headers
  attr_reader   :http_hook
  attr_accessor :auth

  def initialize(url, headers = {}, &http_hook)
    @url = URI.parse(url)
    @headers = DEFAULT_HEADERS.merge(headers)
    @http_hook = http_hook
  end

  def method_missing(method_name)
    Zabbix::Client::Method.new(method_name, self)
  end
end
