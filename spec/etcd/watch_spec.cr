require "../spec_helper"

Spec2.describe "Etcd watch" do
  let :client do
    Etcd.client(["localhost:4001"])
  end

  it "without index, returns the value at a particular index" do
    key = random_key(4)
    value1 = SecureRandom.uuid
    value2 = SecureRandom.uuid

    index1 = client.create(key, {value: value1}).node.modified_index
    index2 = client.compare_and_swap(key, {value: value2, prevValue: value1}).node.modified_index

    expect(client.watch(key, {index: index1}).node.value).to eq(value1)
    expect(client.watch(key, {index: index2}).node.value).to eq(value2)
  end

  it "with index, waits and return when the key is updated" do
    key = random_key

    value = SecureRandom.uuid
    channel = Channel(Etcd::Response).new

    spawn do
      channel.send(client.watch(key))
    end
    sleep 2
    client.set(key, {value: value})

    response = channel.receive
    expect(response.node.value).to eq(value)
  end

  it "with recrusive, waits and return when the key is updated" do
    key = random_key
    value = SecureRandom.uuid
    client.set("#{key}/subkey", {value: "initial_value"})

    channel = Channel(Etcd::Response).new

    spawn do
      channel.send(client.watch(key, {recursive: true, timeout: "3"}))
    end

    sleep 2
    client.set("#{key}/subkey", {value: value})

    response = channel.receive
    expect(response.node.value).to eq(value)
  end
end
