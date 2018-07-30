require "http/client"
require "json"
require "./etcd/config"
require "./etcd/errors"
require "./etcd/node"
require "./etcd/options"
require "./etcd/response"
require "./etcd/keys"
require "./etcd/stats"
require "./etcd/client"

##
# This module provides the Etcd:: name space for the gem and few
# factory methods for Etcd domain objects
module Etcd
  ##
  # Create and return a Etcd::Client object. It a string or an array of Strings
  # as an argument which gets passed to the Etcd::Client.new method
  # directly


  def self.client(addr : String = "localhost:2379") : Etcd::Client
    Etcd::Client.new([addr])
  end

  def self.client(addr : String = "localhost:2379", &block) : Etcd::Client
    Etcd::Client.new([addr]) do |config|
      yield config
    end
  end

  def self.client(addrs : Array(String)) : Etcd::Client
    Etcd::Client.new(addrs)
  end

  def self.client(addrs : Array(String), &block) : Etcd::Client
    Etcd::Client.new(addrs) do |config|
      yield config
    end
  end
end
