require "spec2"
require "../src/etcd"
require "secure_random"
require "./support/*"

def random_key(n = 1)
  String.build do |key|
    n.times do
      key << '/' + SecureRandom.uuid
    end
  end
end

def etcd_leader
  servers = ENV.fetch("ETCD_SERVERS", "localhost:4001,localhost:4002,localhost:4003")
  clients = servers.split(",").map do |srv|
    Etcd.client(srv)
  end.to_a

  clients.find do |c|
    c.stats(:self)["state"] == "StateLeader"
  end.not_nil!
end

Spec2.register_matcher(be_directory) do
  BeDirectoryMatcher(Etcd::Node).new
end
