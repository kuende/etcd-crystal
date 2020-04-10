require "../spec_helper"

private def set_message_value
  client.set("/message", {:value => "PinkFloyd"}).as(Etcd::Response)
end

private def set_get_message_value
  client.set("/message", {:value => "PinkFloyd"})
  client.get("/message")
end

private def double_set_message_value
  client.set("/message", {:value => "World"})
  client.set("/message", {:value => "PinkFloyd"})
end

private def double_set_message_value_with_ttl
  client.set("/message", {:value => "World"})
  client.set("/message", {:value => "PinkFloyd", :ttl => "5"})
end

private def double_set_delete_message_value
  client.set("/message", {:value => "World"})
  client.set("/message", {:value => "PinkFloyd"})
  client.delete("/message")
end

private def wait_change_response
  client.set("/message", {:value => "foo"})

  channel = Channel(Etcd::Response).new

  spawn do
    channel.send(client.watch("/message"))
  end

  sleep 0.1
  client.set("/message", {:value => "PinkFloyd"})
  channel.receive
end

private def atomic_in_order_response
  client.create_in_order("/queue", {:value => "PinkFloyd"})
end

describe "Etcd specs for the main etcd README examples" do
  describe "set a key named '/message'" do
    # it_should_behave_like 'response with valid http headers'
    # it_should_behave_like 'response with valid node data'

    it "should set the return action to SET" do
      set_message_value.action.should eq("set")
    end
  end

  describe "get a key named '/message'" do
    # it_should_behave_like 'response with valid http headers'
    # it_should_behave_like 'response with valid node data'

    it "should set the return action to GET" do
      set_get_message_value.action.should eq("get")
    end
  end


  describe "change the value of a key named '/message'" do
    # it_should_behave_like 'response with valid http headers'
    # it_should_behave_like 'response with valid node data'

    it "should set the return action to SET" do
      double_set_message_value.action.should eq("set")
    end
  end

  describe "delete a key named '/message'" do
    it "should set the return action to SET" do
      double_set_delete_message_value.action.should eq("delete")
    end

    # it_should_behave_like 'response with valid http headers'
    # it_should_behave_like 'response with valid node data', :delete
  end

  describe "using ttl a key named '/message'" do
    # it_should_behave_like 'response with valid http headers'
    # it_should_behave_like 'response with valid node data'

    it "should set the return action to SET" do
      double_set_message_value_with_ttl.action.should eq("set")
    end

    it "should have valid expiration time" do
      double_set_message_value_with_ttl.node.expiration.should_not be_nil
    end

    it "should have ttl available from the node" do
      double_set_message_value_with_ttl.node.ttl.should eq(5)
    end

    it "should throw exception after the expiration time" do
      sleep 8
      expect_raises Etcd::KeyNotFound do
        client.get("/message")
      end
    end
  end

  describe "waiting for a change against a key named '/message'" do
  #  it_should_behave_like 'response with valid http headers'
  #  it_should_behave_like 'response with valid node data'

    it "should set the return action to SET" do
      wait_change_response.action.should eq("set")
    end

    it "should get the exact value by specifying a waitIndex" do
      client.set("/message", {:value => "someshit"})
      w_response = client.watch("/message", {:index => wait_change_response.node.modified_index})
      w_response.node.value.should eq("PinkFloyd")
    end
  end

  context "atomic in-order keys" do
    # it_should_behave_like 'response with valid http headers'
    # it_should_behave_like 'response with valid node data', :create

    it "should set the return action to create" do
      atomic_in_order_response.action.should eq("create")
    end

    it "should have the child key as a positive integer" do
      (atomic_in_order_response.key.split("/").last.to_i > 0).should be_truthy
    end

    it "should have the child keys as monotonically increasing" do
      first_response = client.create_in_order("/queue", {:value => "The Jimi Hendrix Experience"})
      second_response = client.create_in_order("/queue", {:value => "The Doors"})
      first_key = first_response.key.split("/").last.to_i
      second_key = second_response.key.split("/").last.to_i
      (first_key < second_key).should be_truthy
    end

    it "should enlist all children in sorted manner" do
      responses = 10.times.map do |n|
        client.create_in_order("/queue", {:value => "Deep Purple - Track #{n}"})
      end.to_a

      directory = client.get("/queue", {:sorted => true})

      past_index = directory.children.index do |el|
        el.key == responses.first.node.key && el.modified_index == responses.first.node.modified_index
      end.not_nil!

      9.times do |n|
        current_index = directory.children.index do |el|
          el.key == responses[n + 1].node.key && el.modified_index == responses[n + 1].node.modified_index
        end.not_nil!
        (current_index > past_index).should be_truthy
        past_index = current_index
      end
    end
  end

  describe "directory with ttl" do
    before_each do
      client.set("/directory", Etcd::Options{:dir => true, :ttl => "4"})
    end

    after_each do
      begin
        client.delete("/directory", {:dir => true, :recursive => true})
      rescue Etcd::KeyNotFound
        # Some tests expire the /directory key
      end
    end

    it "should create a directory" do
      client.get("/directory").node.not_nil!.dir.should be_truthy
    end

    it "should have valid expiration time" do
      client.get("/directory").node.expiration.should_not be_nil
    end

    it "should have pre-designated ttl" do
      client.get("/directory").node.ttl.should eq(4)
    end

    it "will throw error if updated without setting prevExist" do
      expect_raises Etcd::NotFile do
        client.set("/directory", {:dir => true, :ttl => "5"})
      end
    end

    it "can be updated by setting  prevExist to true" do
      client.set("/directory", {:prevExist => true, :dir => true, :ttl => "5"})
      client.get("/directory").node.ttl.should eq(5)
    end

    it "watchers should get expiry notification" do
      client.set("/directory/a", {:value => "Test"})
      client.set("/directory", {:prevExist => true, :dir => true, :ttl => "2"})

      response = client.watch("/directory/a", {:consistent => true}, 3)
      response.action.should eq("expire")
    end

    it "should be expired after ttl" do
      sleep 5
      expect_raises Etcd::KeyNotFound do
        client.get("/directory")
      end
    end
  end

  describe "atomic compare and swap" do
    it "should  raise error if prevExist is passed a false" do
      client.set("/foo", {:value => "one"})
      expect_raises Etcd::NodeExist do
        client.set("/foo", {:value => "three", :prevExist => false})
      end
    end

    it "should raise error is prevValue is wrong" do
      client.set("/foo", {:value => "one"})
      expect_raises Etcd::TestFailed do
        client.set("/foo", {:value => "three", :prevValue => "two"})
      end
    end

    it "should allow setting the value when prevValue is right" do
      client.set("/foo", {:value => "one"})
      client.set("/foo", {:value => "three", :prevValue => "one"}).value.should eq("three")
    end
  end

  describe "directory manipulation" do
    after_each do
      ["/dir", "/foo_dir"].each do |dir|
        begin
          client.delete(dir, {:dir => true, :recursive => true})
        rescue Etcd::KeyNotFound
          # may be expired
        end
      end
    end

    it "should allow creating directory" do
      client.set("/dir", {:dir => true}).node.not_nil!.dir.should be_truthy
    end

    it "should allow listing directory" do
      client.set("/foo_dir/foo", {:value => "bar"})

      keys = client.get("/").not_nil!.children.map do |node|
        node.key
      end

      keys.to_a.includes?("/foo_dir").should be_truthy
    end

    it "should allow recursive directory listing" do
      client.set("/foo_dir/foo", {:value => "bar"})
      response = client.get("/", {:recursive => true}).not_nil!
      response.children.find{|n| n.key == "/foo_dir" }.not_nil!.children.size.should_not eq(0)
    end

    it "should be able to delete empty directory without the recursive flag" do
      client.set("/dir", {:dir => true})
      client.delete("/dir", {:dir => true}).action.should eq("delete")
    end

    it "should be able to delete directory with children with the recusrive flag" do
      client.set("/foo_dir/foo", {:value => "bar"})
      client.delete("/foo_dir", {:recursive => true}).action.should eq("delete")
    end
  end

  describe "hidden nodes" do
    before_each do
      client.set("/_message", {:value => "Hello Hidden World"})
      client.set("/message", {:value => "Hello World"})
    end

    it "should not be visible in directory listing" do
      keys = client.get("/").children.map do |node|
        node.key
      end
      keys.to_a.includes?("_message").should be_false
    end
  end
end
