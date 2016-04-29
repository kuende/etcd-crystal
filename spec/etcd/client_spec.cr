require "../spec_helper"

Spec2.describe Etcd::Client do
  let(:client) do
    Etcd.client(["localhost:4001"])
  end

  it "#version" do
    server_version = client.version["etcdserver"].to_s
    cluster_version = client.version["etcdcluster"].to_s
    expect(server_version).to match(/^\d+\.\d+\.\d+$/)
    expect(cluster_version).to match(/^\d+\.\d+\.\d+$/)
  end

  it "#version_prefix" do
    expect(client.version_prefix).to eq("/v2")
  end

  context "#api_execute" do
    it "should raise exception when non http methods are passed" do
      expect do
        client.api_execute("/v2/keys/x", "DO")
      end.to raise_error
    end
  end

  context "#http header based metadata" do
    let(:response) do
      key = random_key
      value = SecureRandom.uuid
      client.set(key, {value: value}).not_nil! as Etcd::Response
    end

    it "#etcd_index" do
      expect(response.etcd_index).not_to be_nil
    end

    it "#raft_index" do
      expect(response.raft_index).not_to be_nil
    end

    it "raft_term" do
      expect(response.raft_index).not_to be_nil
    end
  end
end
