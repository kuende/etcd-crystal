require "../spec_helper"

private def response
  key = random_key
  value = UUID.random.to_s
  client.set(key, {:value => value}).not_nil!.as(Etcd::Response)
end

describe Etcd::Client do
  describe "initialization" do
    it "can be initialized using no arguments" do
      c = Etcd.client
      c.addrs.should eq(["localhost:2379"])
    end

    it "can be initialized using block" do
      c = Etcd.client("localhost:5001") do |config|
        config.user_name = "foo"
        config.password = "bar"
      end
      c.addrs.should eq(["localhost:5001"])
      c.config.user_name.should eq("foo")
      c.config.password.should eq("bar")
    end

    it "can be initialized using block and no arguments" do
      c = Etcd.client do |config|
        config.user_name = "foo"
        config.password = "bar"
      end
      c.addrs.should eq(["localhost:2379"])
      c.config.user_name.should eq("foo")
      c.config.password.should eq("bar")
    end

    it "can be initialized using list of addresses" do
      c = Etcd.client(["localhost:2379", "localhost:4002", "localhost:4003"])
      c.addrs.should eq(["localhost:2379", "localhost:4002", "localhost:4003"])
    end

    it "can be initialized using list of addresses and block" do
      c = Etcd.client(["localhost:2379", "localhost:4002", "localhost:4003"]) do |config|
        config.user_name = "foo"
        config.password = "bar"
      end
      c.addrs.should eq(["localhost:2379", "localhost:4002", "localhost:4003"])
      c.config.user_name.should eq("foo")
      c.config.password.should eq("bar")
    end
  end

  it "#version" do
    server_version = client.version["etcdserver"].to_s
    cluster_version = client.version["etcdcluster"].to_s
    server_version.should match(/^\d+\.\d+\.\d+$/)
    cluster_version.should match(/^\d+\.\d+\.\d+$/)
  end

  it "#version_prefix" do
    client.version_prefix.should eq("/v2")
  end

  context "#api_execute" do
    it "should raise exception when non http methods are passed" do
      expect_raises Etcd::HTTPError do
        client.api_execute("/v2/keys/x", "DO")
      end
    end
  end

  context "#http header based metadata" do
    it "#etcd_index" do
      response.etcd_index.should_not be_nil
    end

    it "#raft_index" do
      response.raft_index.should_not be_nil
    end

    it "raft_term" do
      response.raft_index.should_not be_nil
    end
  end
end
