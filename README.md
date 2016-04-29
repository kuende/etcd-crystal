# Etcd

A crystal client for [etcd](https://github.com/coreos/etcd). Heavily inspired from the ruby etcd [client](https://github.com/ranjib/etcd-ruby).

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  etcd:
    github: kuende/etcd-crystal
```


## Usage

### Create a client object

```crystal
require "etcd"

client = Etcd.client # this will create a client against etcd server running on localhost on port 4001
client = Etcd.client("localhost:4001")
client = Etcd.client do |config|
  config.user_name = "foo"
  config.password = "bar"
end
client = Etcd.client("localhost:4001") do |config|
  config.user_name = "foo"
  config.password = "bar"
end
```

### Set a key

```crystal
client.set("/nodes/n1", {value: "1"})
# with ttl
client.set("/nodes/n2", {value: "2", ttl: "4"})  # sets the ttl to 4 seconds
```

### Get a key

```crystal
client.get("/nodes/n2").value
```

### Delete a key

```crystal
client.delete("/nodes/n1")
client.delete("/nodes/", {recursive: true})
```

### Compare and swap

```crystal
client.compare_and_swap("/nodes/n2", {value: "2", prevValue: "4"}) # will set /nodes/n2 's value to 2 only if its previous value was 4
```

### Watch a key

```crystal
client.watch("/nodes/n1") # will wait till the key is changed, and return once its changed
client.watch("/nodes/n1", Etcd::Options.new, 3) # watch a key with timeout

client.watch("/nodes/n1", {recursive: true}) # watch a directory recursive
client.watch("/nodes/n1", {recursive: true}, 3) # watch a directory recursive with timeout
```

### List sub keys

```crystal
client.get("/nodes")
```

## TODO

- [ ] support SSL options
- [ ] failover support, currently only the first server provided is used

## Contributing

1. Fork it ( https://github.com/kuende/etcd-crystal/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request
