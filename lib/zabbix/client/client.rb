class Zabbix::Client
  DEFAULT_HEADERS = {
    'Content-Type' => 'application/json-rpc'
  }

  class Method
    JSON_RPC_VERSION = '2.0'
    JSON_RPC_REQUEST_ID = 1
    LOGIN_METHOD = 'user.login'

    def initialize(prefix, url, headers, http_hook)
      @prefix = prefix
      @url = url
      @headers = headers
      @http_hook = http_hook
    end

    def method_missing(method_name, *args, &block)
      validate_args(args)

      method = "#{@prefix}.#{method_name}"
      params = args[0] || []
      options = args[1] || {}
      response = query(method, params, options)

      if (error = response['error'])
        error = error.merge('method' => method, 'params' => params, 'options' => options)
        raise Zabbix::Client::Error.new(error)
      end

      result = response['result']

      if method == LOGIN_METHOD
        @auth = result
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

      body[:auth] = @auth if @auth
      body = JSON.dump(body)

      http = Net::HTTP.new(@url.host, @url.port)

      if @url.scheme == 'https'
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      @http_hook.call(http) if @http_hook

      http.start do |h|
        response = h.post(@url.path, body, @headers)
        JSON.parse(response.body)
      end
    end

    def validate_args(args)
      unless (0..2).include?(args.length)
        raise ArgumentError, "wrong number of arguments: #{args.inspect} (#{args.length} for 1..2)"
      end

      args.each do |arg|
        unless arg.kind_of?(Hash)
          raise TypeError, "wrong argument: #{arg.inspect} (expected Hash)"
        end
      end
    end
  end # Method

  def initialize(url, headers = {}, &http_hook)
    @url = URI.parse(url)
    @headers = DEFAULT_HEADERS.merge(headers)
    @http_hook = http_hook
  end

  def method_missing(method_name)
    Zabbix::Client::Method.new(method_name, @url, @headers, @http_hook)
  end
end
