module Etcd
  class Client
    # Addresses like ['localhost:4001']
    @addrs : Array(String)
    property config : Config

    include Keys

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
    def api_execute(path : String, method : String, params : Options = Options.new, timeout : Int32? = nil) : HTTP::Client::Response
      client = new_client
      client.basic_auth(@config.user_name, @config.password)
      client.read_timeout = timeout || @config.read_timeout

      body = params.map do |k, v|
        "#{URI.escape(k.to_s)}=#{URI.escape(v.to_s)}"
      end.join("&")

      if ["POST", "PUT"].includes?(method)
        headers = HTTP::Headers{"Content-type": "application/x-www-form-urlencoded"}
      else
        # Set url encoded form as query string for GET and DELETE
        path = "#{path}?#{body}"
        body = ""
        headers = HTTP::Headers.new
      end

      response = client.exec(method, path, body: body, headers: headers)

      client.close

      process_http_request(response)
    end

    # This method returns a new client for a server from list
    # It keeps an internal structure of healthy servers and picks one from the list
    # Currently returns the first server
    def new_client : HTTP::Client
      server = @addrs.first
      host, port = server.split(":")
      HTTP::Client.new(host, port.to_i)
    end

    def process_http_request(response : HTTP::Client::Response) : HTTP::Client::Response
      case
      when (200..299).includes?(response.status_code)
        # Log.debug('Http success')
        response
      when (400..499).includes?(response.status_code)
        raise Error.from_http_response(response)
      else
        # Log.debug('Http error')
        # Log.debug(res.body)
        raise HTTPError.new("Unknown status: #{response.status_code}, response: #{response.body}")
        # response.error!
      end
    end
  end
end
