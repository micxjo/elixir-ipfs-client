defmodule ClientTest do
  use ExUnit.Case, async: true
  import Mock

  defp make_url(path) do
    "http://localhost:5001/api/v0/#{path}"
  end

  test "Test version request" do
    with_mock HTTPoison, [get!: fn("http://localhost:5001/api/v0/version") ->
                           %HTTPoison.Response{
                             status_code: 200,
                             body: """
                             {"Version": "an_awesome_version",
                             "Commit": "commit_1"}
                             """} end] do
      assert IPFS.Client.version == %IPFS.Client.Version{
        version: "an_awesome_version",
        commit: "commit_1"}
    end
  end

  test "Test swarm_peers request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/swarm/peers") ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Strings": ["/ip4/127.0.0.1/tcp/4001/ipfs/blah",
                               "/ip4/4.4.4.1/tcp/2777/ipfs/hash"]}
                               """} end] do
      assert IPFS.Client.swarm_peers == [
        "/ip4/127.0.0.1/tcp/4001/ipfs/blah",
        "/ip4/4.4.4.1/tcp/2777/ipfs/hash"]
    end
  end

  test "Test swarm_addrs request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/swarm/addrs") ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Addrs": {
                                 "a_valid_hash_code": [
                                   "/ip4/127.0.0.1/tcp/4001",
                                   "/ip6/::1/tcp/4201"],
                                 "another_hash": [
                                   "/ip4/4.4.4.1/tcp/42"],
                                 "an_empty_one": []}}
                                 """} end] do
      assert IPFS.Client.swarm_addrs == %{
        "a_valid_hash_code" => ["/ip4/127.0.0.1/tcp/4001",
                                "/ip6/::1/tcp/4201"],
        "another_hash" => ["/ip4/4.4.4.1/tcp/42"],
        "an_empty_one" => []}
    end
  end

  test "Test object_get request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/object/get/a_key") ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Links": [{"Name": "index.html",
                                           "Hash": "hash_of_index",
                                           "Size": 4118930},
                                          {"Name": "main.js",
                                           "Hash": "hash_of_js",
                                           "Size": 683024}],
                                "Data": "\u0008\u0001"}
                                """} end] do
      assert IPFS.Client.object_get("a_key") == %IPFS.Client.Object{
        links: [%IPFS.Client.Link{name: "index.html",
                                  hash: "hash_of_index",
                                  size: 4118930},
                %IPFS.Client.Link{name: "main.js",
                                  hash: "hash_of_js",
                                  size: 683024}],
        data: <<8, 1>>}
    end
  end

  test "Test object_stat request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/object/stat/a_key") ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Hash": "a_key",
                                "NumLinks": 4,
                                "BlockSize": 5,
                                "LinksSize": 3,
                                "DataSize": 500,
                                "CumulativeSize": 7000}
                                """} end] do
      assert IPFS.Client.object_stat("a_key") == %IPFS.Client.ObjectStat{
        hash: "a_key",
        num_links: 4,
        block_size: 5,
        links_size: 3,
        data_size: 500,
        cumulative_size: 7000}
    end
  end

  test "Test block_get request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/block/get/a_key") ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: <<42, 43, 44>>} end] do
      assert IPFS.Client.block_get("a_key") == <<42, 43, 44>>
    end
  end

  test "Test local_id request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/id") ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"ID": "a_peer_id",
                               "PublicKey": "CAAPubKey0123",
                               "Addresses": [
                               "/ip4/127.0.0.1/tcp/4001/ipfs/a_peer_id",
                               "/ip6/::1/tcp/4001/ipfs/a_peer_id"],
                               "AgentVersion": "go-ipfs/0.3.11-dev",
                               "ProtocolVersion": "ipfs/0.1.0"}
                               """} end] do
      assert IPFS.Client.local_id == %IPFS.Client.ID{
        id: "a_peer_id",
        public_key: "CAAPubKey0123",
        addresses: [
          "/ip4/127.0.0.1/tcp/4001/ipfs/a_peer_id",
          "/ip6/::1/tcp/4001/ipfs/a_peer_id"],
        agent_version: "go-ipfs/0.3.11-dev",
        protocol_version: "ipfs/0.1.0"}
    end
  end

  test "Test id request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/id/a_peer_id") ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"ID": "a_peer_id",
                               "PublicKey": "CAAPubKey0123",
                               "Addresses": [
                               "/ip4/127.0.0.1/tcp/4001/ipfs/a_peer_id",
                               "/ip6/::1/tcp/4001/ipfs/a_peer_id"],
                               "AgentVersion": "go-ipfs/0.3.11-dev",
                               "ProtocolVersion": "ipfs/0.1.0"}
                               """} end] do
      assert IPFS.Client.id("a_peer_id") == %IPFS.Client.ID{
        id: "a_peer_id",
        public_key: "CAAPubKey0123",
        addresses: [
          "/ip4/127.0.0.1/tcp/4001/ipfs/a_peer_id",
          "/ip6/::1/tcp/4001/ipfs/a_peer_id"],
        agent_version: "go-ipfs/0.3.11-dev",
        protocol_version: "ipfs/0.1.0"}
    end
  end
end
