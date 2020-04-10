require "../spec_helper"

describe Etcd::Node do
  it "should create a directory with parent key when nested keys are set" do
    parent = random_key
    child = random_key
    value = UUID.random.to_s
    client.set(parent + child, {:value => value})
    client.get(parent + child).node.not_nil!.dir.should be_false
    client.get(parent).node.not_nil!.dir.should be_true
  end

  context "#children" do
    it "should raise exception when invoked against a leaf node" do
      parent = random_key
      client.create(parent, {:value => "10"})
      expect_raises Etcd::IsNotDirectory do
        client.get(parent).children
      end
    end
  end
end
