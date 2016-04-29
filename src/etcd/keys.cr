module Etcd
  # Keys module provides the basic key value operations against
  # etcd /keys namespace
  module Keys
    # return etcd endpoint that is reserved for key/value store
    def key_endpoint
      version_prefix + "/keys"
    end

    # Retrives a key with its associated data, if key is not present it will
    # return with message "Key Not Found"
    #
    # This method takes the following parameters as arguments
    # * key - whose data is to be retrieved
    def get(key : String, opts : Options = Options.new) : Response
      response = api_execute(key_endpoint + key, "GET", opts)
      Response.from_http_response(response)
    end

    # Create or update a new key
    #
    # This method takes the following parameters as arguments
    # * key   - whose value to be set
    # * value - value to be set for specified key
    # * ttl   - shelf life of a key (in seconds) (optional)
    def set(key : String, opts : Options = Options.new) : Response
      path  = key_endpoint + key
      payload = {} of Symbol => JSON::Type
      [:ttl, :value, :dir, :prevExist, :prevValue, :prevIndex].each do |k|
        payload[k] = opts[k] if opts.has_key?(k)
      end
      response = api_execute(path, "PUT", payload)
      Response.from_http_response(response)
    end


    # Deletes a key (and its content)
    #
    # This method takes the following parameters as arguments
    # * key - key to be deleted
    def delete(key : String, opts : Options = Options.new) : Response
      response = api_execute(key_endpoint + key, "DELETE", opts)
      Response.from_http_response(response)
    end


    # Gives a notification when specified key changes
    #
    # This method takes the following parameters as arguments
    # @ key   - key to be watched
    # @options [Hash] additional options for watching a key
    # @options [Fixnum] :index watch the specified key from given index
    # @options [Fixnum] :timeout specify http timeout
    def watch(key : String, opts : Options = Options.new, timeout : Int32 = -1) : Response
      params = { wait: true } of Symbol => JSON::Type
      timeout = timeout != -1 ? timeout : @config.read_timeout
      index = opts.fetch(:waitIndex, opts.fetch(:index, nil))
      params[:waitIndex] = index unless index.nil?
      params[:consistent] = opts[:consistent] if opts.has_key?(:consistent)
      params[:recursive] = opts[:recursive] if opts.has_key?(:recursive)

      response = api_execute(key_endpoint + key, "GET", params, timeout)
      Response.from_http_response(response)
    end

    def create_in_order(dir : String, opts : Options = Options.new) : Response
      path  = key_endpoint + dir
      payload = {} of Symbol => JSON::Type
      [:ttl, :value].each do |k|
        payload[k] = opts[k] if opts.has_key?(k)
      end
      response = api_execute(path, "POST", payload)
      Response.from_http_response(response)
    end

    def exists?(key)
      # Etcd::Log.debug("Checking if key:' #{key}' exists")
      get(key)
      true
    rescue e : KeyNotFound
      # Etcd::Log.debug("Key does not exist #{e}")
      false
    end

    def create(key : String, opts : Options)
      set(key, opts.merge({prevExist: false}))
    end

    def create(key : String)
      set(key, Options{prevExist: false})
    end

    def update(key : String, opts : Options)
      set(key, opts.merge({prevExist: true}))
    end

    def update(key : String)
      set(key, Options{prevExist: true})
    end
  end
end
