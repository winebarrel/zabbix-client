class Zabbix::Client
  class Method
    JSON_RPC_VERSION = '2.0'
    JSON_RPC_REQUEST_ID = 1

    LOGIN_METHOD = 'user.login'
    LOGOUT_METHOD = 'user.logout'

    UNAUTHENTICATED_METHODS = [
      'user.login',
      'apiinfo.version',
    ]

    DEFAULT_HEADERS = {
      'Content-Type' => 'application/json-rpc'
    }

    def initialize(prefix, client)
      @prefix = prefix
      @client = client
    end

    def method_missing(method_name, *args, &block)
      validate_args(args)

      method  = "#{@prefix}.#{method_name}"
      params  = args[0] || []
      options = args[1] || {}

      response = query(method, params, options)

      if (error = response['error'])
        error = error.merge('method' => method, 'params' => params)
        raise Zabbix::Client::Error.new(error)
      end

      result = response['result']

      case method
      when LOGIN_METHOD
        @client.auth = result
      when LOGOUT_METHOD
        @client.auth = nil
      end

      if block
        block.call(result)
      else
        result
      end
    end

    private

    def query(method, params, options)
      options = (@client.options || {}).merge(options)

      body = {
        :jsonrpc => JSON_RPC_VERSION,
        :method  => method,
        :params  => params,
        :id      => JSON_RPC_REQUEST_ID,
      }.merge(options[:json_rpc_request] || {})

      if @client.auth and not UNAUTHENTICATED_METHODS.include?(method)
        body[:auth] = @client.auth
      end

      body = JSON.dump(body)

      proxy_host = options[:proxy_host]
      proxy_port = options[:proxy_port]
      http = Net::HTTP.Proxy(proxy_host, proxy_port).new(@client.url.host, @client.url.port)

      if @client.url.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      http.set_debug_output($stderr) if options[:debug]

      http.start do |h|
        headers = DEFAULT_HEADERS.merge(options[:headers] || {})
        path = @client.url.path
        path = '/' if path.empty?
        request = Net::HTTP::Post.new(path, headers)
        request.body = body

        basic_auth_user = options[:basic_auth_user]
        basic_auth_password = options[:basic_auth_password]

        if basic_auth_user and basic_auth_password
          request.basic_auth(basic_auth_user, basic_auth_password)
        end

        response = h.request(request)

        begin
          JSON.parse(response.body)
        rescue JSON::ParserError
          response.value
          # Throw the following exception if no exception is thrown
          raise [response.code, response.message.dump, response.body].join(' ')
        end
      end
    end

    def validate_args(args)
      unless (0..2).include?(args.length)
        raise ArgumentError, "wrong number of arguments: #{args.inspect} (#{args.length} for 0..2)"
      end

      params, options = args.values_at(0, 1)

      unless params.nil? or params.kind_of?(Hash) or params.kind_of?(Array)
        raise TypeError, "wrong argument: #{params.inspect} (expected Hash or Array)"
      end

      unless options.nil? or options.kind_of?(Hash)
        raise TypeError, "wrong argument: #{options.inspect} (expected Hash)"
      end
    end
  end # Method

  attr_reader   :url
  attr_reader   :options
  attr_accessor :auth

  def initialize(url, options = {})
    @url = URI.parse(url)
    @options = options
  end

  def method_missing(method_name)
    Zabbix::Client::Method.new(method_name, self)
  end
end
