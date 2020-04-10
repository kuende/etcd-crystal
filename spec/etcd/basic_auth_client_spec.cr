require "../spec_helper"

private def client
  Etcd.client(["localhost:2379"]) do |config|
    config.user_name = "test"
    config.password = "pwd"
  end
end

describe "Etcd basic auth client" do
  it "#user_name" do
    client.config.user_name.should eq("test")
  end

  it "#password" do
    client.config.password.should eq("pwd")
  end
end
