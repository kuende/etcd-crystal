module Etcd
  class HTTPError < Exception; end
  class IsNotDirectory < Exception; end

  class Error < Exception
    property reason : String
    property error_code : Int64
    property index : Int64

    def initialize(opts : Hash(String, JSON::Any))
      super(opts["message"].as_s)
      @reason = opts["cause"].as_s
      @index = opts["index"].as_i64
      @error_code = opts["errorCode"].as_i64
    end

    def self.from_http_response(response : HTTP::Client::Response)
      opts = JSON.parse(response.body)
      code = opts["errorCode"].as_i
      unless ERROR_CODE_MAPPING.has_key?(code)
        raise HTTPError.new("Unknown error code: #{code}")
      end
      ERROR_CODE_MAPPING[code].new(opts.as_h)
    rescue JSON::ParseException
      raise HTTPError.new(response.body)
    end

    def inspect
      "<#{self.class}: index:#{index}, code:#{error_code}, cause:'#{reason}'>"
    end
  end

  # command related error
  class KeyNotFound < Error; end
  class TestFailed < Error; end
  class NotFile < Error; end
  class NoMorePeer < Error; end
  class NotDir < Error; end
  class NodeExist < Error; end
  class KeyIsPreserved < Error; end
  class DirNotEmpty < Error; end

  # Post form related error
  class ValueRequired < Error; end
  class PrevValueRequired < Error; end
  class TTLNaN < Error; end
  class IndexNaN < Error; end

  # Raft related error
  class RaftInternal < Error; end
  class LeaderElect < Error; end

  # Etcd related error
  class WatcherCleared < Error; end
  class EventIndexCleared < Error; end

  ERROR_CODE_MAPPING = {
    # command related error
    100 => KeyNotFound,
    101 => TestFailed,
    102 => NotFile,
    103 => NoMorePeer,
    104 => NotDir,
    105 => NodeExist,
    106 => KeyIsPreserved,
    108 => DirNotEmpty,

    # Post form related error
    200 => ValueRequired,
    201 => PrevValueRequired,
    202 => TTLNaN,
    203 => IndexNaN,

    # Raft related error
    300 => RaftInternal,
    301 => LeaderElect,

    # Etcd related error
    400 => WatcherCleared,
    401 => EventIndexCleared
   }
end
