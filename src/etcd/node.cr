module Etcd
  class Node
    property created_index : Int64?
    property modified_index : Int64?
    property ttl : Int64?
    property key : String?
    property value : String?
    property expiration : String?
    property dir : Bool?
    property children : Array(Node)

    def initialize(opts : Hash(String, JSON::Type))
      @created_index = opts.fetch("createdIndex", nil) as Int64?
      @modified_index = opts.fetch("modifiedIndex", nil) as Int64?
      @ttl = opts.fetch("ttl", nil) as Int64?
      @key = opts.fetch("key", nil) as String
      @value = opts.fetch("value", nil) as String?
      @expiration = opts.fetch("expiration", nil) as String?
      @dir = opts.fetch("dir", false) as Bool
      @children = [] of Node

      if @dir && opts.has_key?("nodes")
        nodes = opts["nodes"] as Array(JSON::Type)
        nodes.each do |data|
          @children << Node.new(JSON::Any.new(data).as_h)
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
