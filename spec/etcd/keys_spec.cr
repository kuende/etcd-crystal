require "../spec_helper"

describe Etcd::Keys do
  describe "basic key operations" do
    it "#set/get" do
      key = random_key
      value = UUID.random.to_s
      client.set(key, {:value => value})

      client.get(key).value.should eq(value)
    end

    describe "#exists?" do
      it "should be true for existing keys" do
        key = random_key
        client.create(key, {:value => "10"})
        client.exists?(key).should be_truthy
      end

      it "should be false for not existing keys" do
        client.exists?(random_key).should be_false
      end
    end

    describe "directory" do
      it "should be able to create a directory" do
        d = random_key
        client.create(d, {:dir => true})

        client.get(d).node.not_nil!.dir.should be_truthy
      end

      describe "empty" do
        it "should be able to delete with dir flag" do
          d = random_key
          client.create(d, {:dir => true})
          client.delete(d, {:dir => true})
          client.exists?(d).should be_false
        end

        it "should not be able to delete without dir flag" do
          d = random_key
          client.create(d, {:dir => true})
          client.create("#{d}/foobar")
          expect_raises Etcd::NotFile do
            client.delete(d)
            # client.delete(d, {dir: true, recursive: true})
          end
        end
      end

      describe "not empty" do
        it "should be able to delete with recursive flag" do
          d = random_key
          client.create(d, {:dir => true})
          client.create("#{d}/foobar")
          client.delete(d, {:dir => true, :recursive => true})
        end

        it "should not be able to delete without recursive flag" do
          d = random_key
          client.create(d, {:dir => true})
          client.create("#{d}/foobar")
          expect_raises Etcd::DirNotEmpty do
            client.delete(d, {:dir => true})
          end
        end
      end
    end
  end
end
