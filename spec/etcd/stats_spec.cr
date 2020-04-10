require "../spec_helper"

describe Etcd::Stats do
  describe "of leader" do
    it "should contain a key for leader" do
      etcd_leader.stats(:leader).should_not be_nil
    end
  end

  it "should show self statistics" do
    client.stats(:self)["name"].should_not be_nil
    client.stats(:self)["state"].should_not be_nil
  end

  it "should show store statistics" do
    client.stats(:store).as_h.keys.size.should_not eq(0)
  end

  it "should raise error for invalid types" do
    expect_raises ArgumentError do
      client.stats(:foo)
    end
  end
end
