module Etcd
  class Node
    property created_index : Int64?
    property modified_index : Int64?
    property ttl : Int64?
    property key : String
    property value : String?
    property expiration : String?
    property dir : Bool?
    property children : Array(Node)

    def initialize(opts : Hash(String, JSON::Any))
      @created_index = opts.fetch("createdIndex", nil).try &.as_i64?
      @modified_index = opts.fetch("modifiedIndex", nil).try &.as_i64?
      @ttl = opts.fetch("ttl", nil).try &.as_i64?
      @key = opts.fetch("key", "/").to_s
      @value = opts.fetch("value", nil).try &.as_s?
      @expiration = opts.fetch("expiration", nil).try &.as_s?
      @dir = opts["dir"]?.try(&.as_bool) || false
      @children = [] of Node

      if @dir && opts.has_key?("nodes")
        nodes = opts["nodes"].as_a
        nodes.each do |data|
          @children << Node.new(data.as_h)
        end
      end
    end

    def children : Array(Node)
      unless @dir
        raise IsNotDirectory.new("Could not access children for node: #{key} is not a directory")
      end

      @children
    end
  end
end
