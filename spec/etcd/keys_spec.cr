require "../spec_helper"

Spec2.describe Etcd::Keys do
  let(:client) do
    Etcd.client(["localhost:4001"])
  end

  describe "basic key operations" do
    it "#set/get" do
      key = random_key
      value = UUID.random.to_s
      client.set(key, {:value => value})

      expect(client.get(key).value).to eq(value)
    end

    describe "#exists?" do
      it "should be true for existing keys" do
        key = random_key
        client.create(key, {:value => "10"})
        expect(client.exists?(key)).to be_truthy
      end

      it "should be false for not existing keys" do
        expect(client.exists?(random_key)).to be_false
      end
    end

    describe "directory" do
      it "should be able to create a directory" do
        d = random_key
        client.create(d, {:dir => true})

        expect(client.get(d).node).to be_directory
      end

      describe "empty" do
        it "should be able to delete with dir flag" do
          d = random_key
          client.create(d, {:dir => true})
          client.delete(d, {:dir => true})
          expect(client.exists?(d)).to be_false
        end

        it "should not be able to delete without dir flag" do
          d = random_key
          client.create(d, {:dir => true})
          client.create("#{d}/foobar")
          expect do
            client.delete(d)
            # client.delete(d, {dir: true, recursive: true})
          end.to raise_error(Etcd::NotFile)
        end
      end

      describe "not empty" do
        it "should be able to delete with recursive flag" do
          d = random_key
          client.create(d, {:dir => true})
          client.create("#{d}/foobar")
          expect do
            client.delete(d, {:dir => true, :recursive => true})
          end.not_to raise_error
        end

        it "should not be able to delete without recursive flag" do
          d = random_key
          client.create(d, {:dir => true})
          client.create("#{d}/foobar")
          expect do
            client.delete(d, {:dir => true})
          end.to raise_error(Etcd::DirNotEmpty)
        end
      end
    end
  end
end
