require "../spec_helper"

Spec2.describe "Etcd specs for the main etcd README examples" do
  let(:client) do
    Etcd.client(["localhost:4001"])
  end

  describe "set a key named '/message'" do
    let(:response) do
      client.set("/message", {value: "PinkFloyd"}) as Etcd::Response
    end

    # it_should_behave_like 'response with valid http headers'
    # it_should_behave_like 'response with valid node data'

    it "should set the return action to SET" do
      expect(response.action).to eq("set")
    end
  end

  describe "get a key named '/message'" do
    let(:response) do
      client.set("/message", {value: "PinkFloyd"})
      client.get("/message")
    end

    # it_should_behave_like 'response with valid http headers'
    # it_should_behave_like 'response with valid node data'

    it "should set the return action to GET" do
      expect(response.action).to eq("get")
    end
  end


  describe "change the value of a key named '/message'" do
    let :response do
      client.set("/message", {value: "World"})
      client.set("/message", {value: "PinkFloyd"})
    end

    # it_should_behave_like 'response with valid http headers'
    # it_should_behave_like 'response with valid node data'

    it "should set the return action to SET" do
      expect(response.action).to eq("set")
    end
  end

  describe "delete a key named '/message'" do
    let :response do
      client.set("/message", {value: "World"})
      client.set("/message", {value: "PinkFloyd"})
      client.delete("/message")
    end

    it "should set the return action to SET" do
      expect(response.action).to eq("delete")
    end

    # it_should_behave_like 'response with valid http headers'
    # it_should_behave_like 'response with valid node data', :delete
  end

  describe "using ttl a key named '/message'" do
    let :response do
      client.set("/message", {value: "World"})
      client.set("/message", {value: "PinkFloyd", ttl: "5"})
    end

    # it_should_behave_like 'response with valid http headers'
    # it_should_behave_like 'response with valid node data'

    it "should set the return action to SET" do
      expect(response.action).to eq("set")
    end

    it "should have valid expiration time" do
      expect(response.node.expiration).not_to be_nil
    end

    it "should have ttl available from the node" do
      expect(response.node.ttl).to eq(5)
    end

    it "should throw exception after the expiration time" do
      sleep 8
      expect do
        client.get("/message")
      end.to raise_error(Etcd::KeyNotFound)
    end
  end

  describe "waiting for a change against a key named '/message'" do
    let :response do
      client.set("/message", {value: "foo"})

      channel = Channel(Etcd::Response).new

      spawn do
         channel.send(client.watch("/message"))
      end

      sleep 0.1
      client.set("/message", {value: "PinkFloyd"})
      channel.receive
    end

  #  it_should_behave_like 'response with valid http headers'
  #  it_should_behave_like 'response with valid node data'

    it "should set the return action to SET" do
      expect(response.action).to eq("set")
    end

    it "should get the exact value by specifying a waitIndex" do
      client.set("/message", {value: "someshit"})
      w_response = client.watch("/message", {index: response.node.modified_index})
      expect(w_response.node.value).to eq("PinkFloyd")
    end
  end

  context "atomic in-order keys" do
    let :response do
      client.create_in_order("/queue", {value: "PinkFloyd"})
    end

    # it_should_behave_like 'response with valid http headers'
    # it_should_behave_like 'response with valid node data', :create

    it "should set the return action to create" do
      expect(response.action).to eq("create")
    end

    it "should have the child key as a positive integer" do
      expect(response.key.split("/").last.to_i > 0).to be_truthy
    end

    it "should have the child keys as monotonically increasing" do
      first_response = client.create_in_order("/queue", {value: "The Jimi Hendrix Experience"})
      second_response = client.create_in_order("/queue", {value: "The Doors"})
      first_key = first_response.key.split("/").last.to_i
      second_key = second_response.key.split("/").last.to_i
      expect(first_key < second_key).to be_truthy
    end

    it "should enlist all children in sorted manner" do
      responses = 10.times.map do |n|
        client.create_in_order("/queue", {value: "Deep Purple - Track #{n}"})
      end.to_a

      directory = client.get("/queue", {sorted: true})

      past_index = directory.children.index do |el|
        el.key == responses.first.node.key && el.modified_index == responses.first.node.modified_index
      end.not_nil!

      9.times do |n|
        current_index = directory.children.index do |el|
          el.key == responses[n + 1].node.key && el.modified_index == responses[n + 1].node.modified_index
        end.not_nil!
        expect(current_index > past_index).to be_truthy
        past_index = current_index
      end
    end
  end


  describe "directory with ttl" do
    before do
      client.set("/directory", Etcd::Options{dir: true, ttl: "4"})
    end

    after do
      begin
        client.delete("/directory", {dir: true, recursive: true})
      rescue Etcd::KeyNotFound
        # Some tests expire the /directory key
      end
    end

    it "should create a directory" do
      expect(client.get("/directory").node).to be_directory
    end

    it "should have valid expiration time" do
      expect(client.get("/directory").node.expiration).not_to be_nil
    end

    it "should have pre-designated ttl" do
      expect(client.get("/directory").node.ttl).to eq(4)
    end

    it "will throw error if updated without setting prevExist" do
      expect do
        client.set("/directory", {dir: true, ttl: "5"})
      end.to raise_error(Etcd::NotFile)
    end

    it "can be updated by setting  prevExist to true" do
      client.set("/directory", {prevExist: true, dir: true, ttl: "5"})
      expect(client.get("/directory").node.ttl).to eq(5)
    end

    it "watchers should get expiry notification" do
      client.set("/directory/a", {value: "Test"})
      client.set("/directory", {prevExist: true, dir: true, ttl: "2"})

      response = client.watch("/directory/a", {consistent: true}, 3)
      expect(response.action).to eq("expire")
    end

    it "should be expired after ttl" do
      sleep 5
      expect do
        client.get("/directory")
      end.to raise_error(Etcd::KeyNotFound)
    end
  end

  describe "atomic compare and swap" do
    it "should  raise error if prevExist is passed a false" do
      client.set("/foo", {value: "one"})
      expect do
        client.set("/foo", {value: "three", prevExist: false})
      end.to raise_error(Etcd::NodeExist)
    end

    it "should raise error is prevValue is wrong" do
      client.set("/foo", {value: "one"})
      expect do
        client.set("/foo", {value: "three", prevValue: "two"})
      end.to raise_error(Etcd::TestFailed)
    end

    it "should allow setting the value when prevValue is right" do
      client.set("/foo", {value: "one"})
      expect(client.set("/foo", {value: "three", prevValue: "one"}).value).to eq("three")
    end
  end

  describe "directory manipulation" do
    after do
      ["/dir", "/foo_dir"].each do |dir|
        begin
          client.delete(dir, {dir: true, recursive: true})
        rescue Etcd::KeyNotFound
          # may be expired
        end
      end
    end

    it "should allow creating directory" do
      expect(client.set("/dir", {dir: true}).node).to be_directory
    end

    it "should allow listing directory" do
      client.set("/foo_dir/foo", {value: "bar"})

      keys = client.get("/").not_nil!.children.map do |node|
        node.key
      end

      expect(keys.to_a.includes?("/foo_dir")).to be_truthy
    end

    it "should allow recursive directory listing" do
      client.set("/foo_dir/foo", {value: "bar"})
      response = client.get("/", {recursive: true}).not_nil!
      expect(response.children.find{|n| n.key == "/foo_dir" }.not_nil!.children.size).not_to eq(0)
    end

    it "should be able to delete empty directory without the recursive flag" do
      client.set("/dir", {dir: true})
      expect(client.delete("/dir", {dir: true}).action).to eq("delete")
    end

    it "should be able to delete directory with children with the recusrive flag" do
      client.set("/foo_dir/foo", {value: "bar"})
      expect(client.delete("/foo_dir", {recursive: true}).action).to eq("delete")
    end
  end

  describe "hidden nodes" do
    before do
      client.set("/_message", {value: "Hello Hidden World"})
      client.set("/message", {value: "Hello World"})
    end

    it "should not be visible in directory listing" do
      keys = client.get("/").children.map do |node|
        node.key
      end
      expect(keys.to_a.includes?("_message")).to be_false
    end
  end
end
