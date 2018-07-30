require "../spec_helper"

Spec2.describe "Etcd basic auth client" do
  let :client do
    Etcd.client(["localhost:2379"]) do |config|
      config.user_name = "test"
      config.password = "pwd"
    end
  end

  it "#user_name" do
    expect(client.config.user_name).to eq("test")
  end

  it "#password" do
    expect(client.config.password).to eq("pwd")
  end
end
