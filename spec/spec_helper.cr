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

Spec2.register_matcher(be_directory) do
  BeDirectoryMatcher(Etcd::Node).new
end
