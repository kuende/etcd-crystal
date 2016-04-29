require "spec2"
require "../src/etcd"
require "secure_random"

def random_key(n = 1)
  String.build do |key|
    n.times do
      key << '/' + SecureRandom.uuid
    end
  end
end
