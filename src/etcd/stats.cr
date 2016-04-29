module Etcd
  # Support stats
  module Stats
    def stats_endpoint
      version_prefix + "/stats"
    end

    def stats(kind : Symbol) : JSON::Any
      case kind
      when :leader
        JSON.parse(api_execute(stats_endpoint + "/leader", "GET").body)
      when :store
        JSON.parse(api_execute(stats_endpoint + "/store", "GET").body)
      when :self
        JSON.parse(api_execute(stats_endpoint + "/self", "GET").body)
      else
        raise ArgumentError.new("Invalid stats type '#{kind}'")
      end
    end
  end
end
