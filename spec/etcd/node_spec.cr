require "../spec_helper"

Spec2.describe Etcd::Node do
  let(:client) do
    Etcd.client(["localhost:4001"])
  end

  it "should create a directory with parent key when nested keys are set" do
    parent = random_key
    child = random_key
    value = UUID.random.to_s
    client.set(parent + child, {:value => value})
    expect(client.get(parent + child).node).not_to be_directory
    expect(client.get(parent).node).to be_directory
  end

  context "#children" do
    it "should raise exception when invoked against a leaf node" do
      parent = random_key
      client.create(parent, {:value => "10"})
      expect do
        client.get(parent).children
      end.to raise_error(Etcd::IsNotDirectory)
    end
  end
end
