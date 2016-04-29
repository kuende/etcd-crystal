module Etcd
  # manage http responses
  class Response
    property actions : String
    property node : Node
    property etcd_index : Int64
    property raft_index : Int64
    property raft_term : Int64

    def initialize(opts : Hash(String, JSON::Type), headers : Hash(Symbol, Int64))
      @actions = opts["action"] as String
      @node = Node.new(opts["node"])
      @etcd_index = headers[:etcd_index]
      @raft_index = headers[:raft_index]
      @raft_term = headers[:raft_term]
    end

    def self.from_http_response(response : HTTP::Client::Response) : Response
      data = JSON.parse(response.body).as_h
      headers = {} of Symbol => Int64
      headers[:etcd_index] = response.headers["X-Etcd-Index"].to_i64
      headers[:raft_index] = response.headers["X-Raft-Index"].to_i64
      headers[:raft_term] = response.headers["X-Raft-Term"].to_i64
      Response.new(data, headers)
    end
  end
end
