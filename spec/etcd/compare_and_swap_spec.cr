require "../spec_helper"

describe "Etcd test_and_set" do
  it "should pass when prev value is correct" do
    key = random_key(2)
    old_value = UUID.random.to_s
    new_value = UUID.random.to_s
    resp = client.set(key, {:value => old_value})
    resp.node.value.should eq(old_value)
    client.compare_and_swap(key, {:value => new_value, :prevValue => old_value})
    client.get(key).value.should eq(new_value)
  end

  it "should fail when prev value is incorrect" do
    key = random_key(2)
    value = UUID.random.to_s
    client.set(key, {:value => value})
    expect_raises Etcd::TestFailed do
      client.compare_and_swap(key, {:value => "10", :prevValue => "2"})
    end
  end

  it "#create should succeed when the key is absent and update should fail" do
    key = random_key(2)
    value = UUID.random.to_s
    expect_raises Etcd::KeyNotFound do
      client.update(key, {:value => value})
    end

    client.create(key, {:value => value})
    client.get(key).value.should eq(value)
  end

  it "#create should fail when the key is present and update should succeed" do
    key = random_key(2)
    value = UUID.random.to_s
    client.set(key, {:value => "1"})

    expect_raises Etcd::NodeExist do
      client.create(key, {:value => value})
    end

    client.update(key, {:value => value})
  end
end
