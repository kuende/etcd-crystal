require "../spec_helper"

Spec2.describe Etcd::Stats do
  let :client do
    Etcd.client(["localhost:2379"])
  end

  let :leader do
    etcd_leader
  end

  describe "of leader" do
    let :stats do
      client.stats(:leader)
    end

    it "should contain a key for leader" do
      expect(leader.stats(:leader)).not_to be_nil
    end
  end

  it "should show self statistics" do
    expect(client.stats(:self)["name"]).not_to be_nil
    expect(client.stats(:self)["state"]).not_to be_nil
  end

  it "should show store statistics" do
    expect(client.stats(:store).as_h.keys.size).not_to eq(0)
  end

  it "should raise error for invalid types" do
    expect do
      client.stats(:foo)
    end.to raise_error(ArgumentError)
  end
end
