require "../spec_helper"

Spec2.describe Etcd::Client do
  let(:client) do
    Etcd.client(["localhost:4001"])
  end

  it "#version" do
    version = client.version
    expect(!!client.version["etcdserver"].to_s.match(/^\d+\.\d+\.\d+$/)).to eq(true)
    expect(!!client.version["etcdcluster"].to_s.match(/^\d+\.\d+\.\d+$/)).to eq(true)
  end
end
