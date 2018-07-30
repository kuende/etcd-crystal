require "../spec_helper"

Spec2.describe "Etcd test_and_set" do
  let :client do
    Etcd.client(["localhost:4001"])
  end

  it "should pass when prev value is correct" do
    key = random_key(2)
    old_value = UUID.random.to_s
    new_value = UUID.random.to_s
    resp = client.set(key, {:value => old_value})
    expect(resp.node.value).to eq(old_value)
    client.compare_and_swap(key, {:value => new_value, :prevValue => old_value})
    expect(client.get(key).value).to eq(new_value)
  end

  it "should fail when prev value is incorrect" do
    key = random_key(2)
    value = UUID.random.to_s
    client.set(key, {:value => value})
    expect do
      client.compare_and_swap(key, {:value => "10", :prevValue => "2"})
    end.to raise_error(Etcd::TestFailed)
  end

  it "#create should succeed when the key is absent and update should fail" do
    key = random_key(2)
    value = UUID.random.to_s
    expect do
      client.update(key, {:value => value})
    end.to raise_error(Etcd::KeyNotFound)

    expect do
      client.create(key, {:value => value})
    end.not_to raise_error
    expect(client.get(key).value).to eq(value)
  end

  it "#create should fail when the key is present and update should succeed" do
    key = random_key(2)
    value = UUID.random.to_s
    client.set(key, {:value => "1"})

    expect do
      client.create(key, {:value => value})
    end.to raise_error(Etcd::NodeExist)

    expect do
      client.update(key, {:value => value})
    end.not_to raise_error
  end
end
