module Etcd
  class Client
    # Addresses like ['localhost:4001']
    @addrs : Array(String)
    property config : Config

    def initialize(@addrs)
      @config = Config.new
    end

    def initialize(@addrs, &block)
      @config = Config.new
      yield @config
    end


    # Returns the etcd api version that will be used for across API methods
    def version_prefix
      "/v2"
    end

    # Returns the etcd daemon version
    def version
      response = api_execute("/version", "GET").body

      JSON.parse(response)
    end

    # This method sends api request to etcd server.
    #
    # This method has following parameters as argument
    # * path    - etcd server path (etcd server end point)
    # * method  - the request method used
    # * options  - any additional parameters used by request method (optional)

    def api_execute(path : String, method : String)
      client = new_client
      client.basic_auth(@config.user_name, @config.password)
      client.exec(method, path)
    end

    # This method returns a new client for a server from list
    # It keeps an internal structure of healthy servers and picks one from the list
    # Currently returns the first server
    def new_client : HTTP::Client
      server = @addrs.first
      host, port = server.split(":")
      HTTP::Client.new(host, port.to_i)
    end


  #   def api_execute(path, method, params : Hash(String,String) = {} of String => String)
  #    case  method
  #    when :get
  #      req = build_http_request(Net::HTTP::Get, path, params)
  #    when :post
  #      req = build_http_request(Net::HTTP::Post, path, nil, params)
  #    when :put
  #      req = build_http_request(Net::HTTP::Put, path, nil, params)
  #    when :delete
  #      req = build_http_request(Net::HTTP::Delete, path, params)
  #    else
  #      fail "Unknown http action: #{method}"
  #    end
  #    http = Net::HTTP.new(host, port)
  #    http.read_timeout = options[:timeout] || read_timeout
  #    setup_https(http)
  #    req.basic_auth(user_name, password) if [user_name, password].all?
  #    Log.debug("Invoking: '#{req.class}' against '#{path}")
  #    res = http.request(req)
  #    Log.debug("Response code: #{res.code}")
  #    Log.debug("Response body: #{res.body}")
  #    process_http_request(res)
  #  end
  end
end
