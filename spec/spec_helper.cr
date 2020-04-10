require "spec"
require "uuid"
require "../src/etcd"

ETCD_SERVERS = [
  "localhost:2379",
  "localhost:4001",
  "localhost:4002"
]

def random_key(n = 1)
  String.build do |key|
    n.times do
      key << '/' + UUID.random.to_s
    end
  end
end

def etcd_leader
  servers = ENV.fetch("ETCD_SERVERS", ETCD_SERVERS.join(','))
  clients = servers.split(",").map do |srv|
    Etcd.client(srv)
  end.to_a

  clients.find do |c|
    c.stats(:self)["state"] == "StateLeader"
  end.not_nil!
end

def client
  Etcd.client(ETCD_SERVERS)
end
