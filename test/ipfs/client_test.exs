defmodule ClientTest do
  use ExUnit.Case, async: true
  import Mock

  test "Uses custom host and port" do
    with_mock HTTPoison, [get!: fn(
                           "http://example.com:6001/api/v0/version", _, _) ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Version": "an_awesome_version",
                               "Commit": "commit_1"}
                               """} end] do
      client = IPFS.Client.new("example.com", 6001)
      assert IPFS.Client.version(client) == {
        :ok, %IPFS.Client.Version{
          version: "an_awesome_version",
          commit: "commit_1"}}
    end
  end

  test "Default user agent is set" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/version",
                           [{"User-agent", _}], _) ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Version": "an_awesome_version",
                               "Commit": "commit_1"}
                               """} end] do
      assert {:ok, _} = IPFS.Client.version
    end
  end

  test "Custom user agent si set" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/version",
                           [{"User-agent", "custom_agent"}], _) ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Version": "an_awesome_version",
                               "Commit": "commit_1"}
                               """} end] do
      client = %IPFS.Client{user_agent: "custom_agent"}
      assert {:ok, _} = IPFS.Client.version(client)
    end
  end

  test "Test version request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/version", _, _) ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Version": "an_awesome_version",
                               "Commit": "commit_1"}
                               """} end] do
      assert IPFS.Client.version == {
        :ok, %IPFS.Client.Version{
        version: "an_awesome_version",
        commit: "commit_1"}}
    end
  end

  test "Test swarm_peers request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/swarm/peers", _, _) ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Strings": ["/ip4/127.0.0.1/tcp/4001/ipfs/blah",
                               "/ip4/4.4.4.1/tcp/2777/ipfs/hash"]}
                               """} end] do
      assert IPFS.Client.swarm_peers == {
        :ok, ["/ip4/127.0.0.1/tcp/4001/ipfs/blah",
              "/ip4/4.4.4.1/tcp/2777/ipfs/hash"]}
    end
  end

  test "Test swarm_addrs request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/swarm/addrs", _, _) ->
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
      assert IPFS.Client.swarm_addrs == {
        :ok, %{
          "a_valid_hash_code" => ["/ip4/127.0.0.1/tcp/4001",
                                  "/ip6/::1/tcp/4201"],
          "another_hash" => ["/ip4/4.4.4.1/tcp/42"],
          "an_empty_one" => []}}
    end
  end

  test "Test swarm_addrs_local request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/swarm/addrs/local",
                           _, _) ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Strings":
                               [
                               "/ip4/127.0.0.1/tcp/4001",
                               "/ip6/::1/tcp/4201"
                               ]}
                               """} end] do
      assert IPFS.Client.swarm_addrs_local == {
        :ok, ["/ip4/127.0.0.1/tcp/4001",
              "/ip6/::1/tcp/4201"]}
    end
  end

  test "Test object_get request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/object/get/a_key",
                           _, _) ->
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
      assert IPFS.Client.object_get("a_key") == {
        :ok, %IPFS.Client.Object{
          links: [%IPFS.Client.Link{name: "index.html",
                                    hash: "hash_of_index",
                                    size: 4118930},
                  %IPFS.Client.Link{name: "main.js",
                                    hash: "hash_of_js",
                                    size: 683024}],
          data: <<8, 1>>}}
    end
  end

  test "Test object_new request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/object/new",
                           _, _) ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Hash":"QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"}
                                """} end] do
      assert IPFS.Client.object_new() == {
        :ok, %IPFS.Client.PatchObject{
          links: [],
          hash: "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"}}
    end
  end

  test "Test object_put request" do
    with_mock HTTPoison, [post!: fn(
                           "http://localhost:5001/api/v0/object/put",
                           {:multipart, [{"data", "{\"Data\":\"dGVzdCBkYXRh\"}"}]},
                           _,
                           _) ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Hash":"QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"}
                                """} end] do
      assert IPFS.Client.object_put("test data", false) == {
        :ok, %IPFS.Client.PatchObject{
          links: [],
          hash: "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"}}
    end
  end

  test "Test object_patch_add_link request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/object/patch/add-link",
                           _, _) ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Hash":"QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"}
                                """} end] do
      assert IPFS.Client.object_patch_add_link("QmaSf39sCs", "/names/1", "QmdoDatULjkor1eA1YhBAjmKkkD", true) == {
        :ok, %IPFS.Client.PatchObject{
          links: [],
          hash: "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"}}
    end
  end

  test "Test object_stat request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/object/stat/a_key",
                           _, _) ->
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
      assert IPFS.Client.object_stat("a_key") == {
        :ok, %IPFS.Client.ObjectStat{
          hash: "a_key",
          num_links: 4,
          block_size: 5,
          links_size: 3,
          data_size: 500,
          cumulative_size: 7000}}
    end
  end

  test "Test block_get request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/block/get/a_key",
                           _, _) ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: <<42, 43, 44>>} end] do
      assert IPFS.Client.block_get("a_key") == {:ok, <<42, 43, 44>>}
    end
  end

  test "Test local_id request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/id", _, _) ->
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
      assert IPFS.Client.local_id == {
        :ok, %IPFS.Client.ID{
          id: "a_peer_id",
          public_key: "CAAPubKey0123",
          addresses: [
            "/ip4/127.0.0.1/tcp/4001/ipfs/a_peer_id",
            "/ip6/::1/tcp/4001/ipfs/a_peer_id"],
          agent_version: "go-ipfs/0.3.11-dev",
          protocol_version: "ipfs/0.1.0"}}
    end
  end

  test "Test id request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/id/a_peer_id", _, _) ->
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
      assert IPFS.Client.id("a_peer_id") == {
        :ok, %IPFS.Client.ID{
          id: "a_peer_id",
          public_key: "CAAPubKey0123",
          addresses: [
            "/ip4/127.0.0.1/tcp/4001/ipfs/a_peer_id",
            "/ip6/::1/tcp/4001/ipfs/a_peer_id"],
          agent_version: "go-ipfs/0.3.11-dev",
          protocol_version: "ipfs/0.1.0"}}
    end
  end

  test "Test bootstrap_list request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/bootstrap/list", _, _) ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Peers":["/ip4/127.0.0.1/tcp/4001/ipfs/abc",
                               "/ip6/::1/udp/4001"]}
                               """} end] do
      assert IPFS.Client.bootstrap_list == {
        :ok, ["/ip4/127.0.0.1/tcp/4001/ipfs/abc",
              "/ip6/::1/udp/4001"]}
    end
  end

  test "Test pin_ls request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/pin/ls", _, _) ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Keys": {
                               "hash_1": {"Type": "recursive", "Count": 1},
                               "hash_2": {"Type": "direct", "Count": 3}}}
                               """} end] do
      assert IPFS.Client.pin_ls == {
        :ok, [%IPFS.Client.Pin{hash: "hash_1", count: 1, type: "recursive"},
              %IPFS.Client.Pin{hash: "hash_2", count: 3, type: "direct"}]}
    end
  end

  test "Test name_publish request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/name/publish", _, _) ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Name":"QmTUESDMNR1Nmf6BzwSFBSRDG6H59PmH1CY4Jx22F3S9TV",
                               "Value":"/ipfs/QmNgGKjCpUTqnoiTFVERnEhQpv9c2wsbHExMUFxzvRGYca"}
                               """} end] do
      assert IPFS.Client.name_publish("QmNgGKjCpUTqnoiTFVERnEhQpv9c2wsbHExMUFxzvRGYca") == {
        :ok, %IPFS.Client.Published{
          name: "QmTUESDMNR1Nmf6BzwSFBSRDG6H59PmH1CY4Jx22F3S9TV",
          value: "/ipfs/QmNgGKjCpUTqnoiTFVERnEhQpv9c2wsbHExMUFxzvRGYca"
          }}
    end
  end

  test "Test name_resolve request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/name/resolve", _, _) ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Path":"/ipfs/QmNgGKjCpUTqnoiTFVERnEhQpv9c2wsbHExMUFxzvRGYca"}
                               """} end] do
      assert IPFS.Client.name_resolve() == {
        :ok, %IPFS.Client.Published{
          value: "/ipfs/QmNgGKjCpUTqnoiTFVERnEhQpv9c2wsbHExMUFxzvRGYca"
          }}
    end
  end

  test "Test key_gen request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/key/gen", _, _) ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Name":"my_key",
                               "Id":"key_id"}
                               """} end] do
      assert IPFS.Client.key_gen("my_key") == {
        :ok, %IPFS.Client.Key{
          name: "my_key",
          id: "key_id"
          }}
    end
  end

  test "Test key_list request" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/key/list", _, _) ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: """
                               {"Keys":[{"Name":"self","Id":"QmSDvVLLVbgrB2DPpowWBFfGLW8TQD38K7j5uCRsvtge7Q"}]}
                               """} end] do
      assert IPFS.Client.key_list() == {
        :ok, [%IPFS.Client.Key{
          name: "self",
          id: "QmSDvVLLVbgrB2DPpowWBFfGLW8TQD38K7j5uCRsvtge7Q"
        }]}
    end
  end

  test "JSON parse failure" do
    with_mock HTTPoison, [get!: fn(
                           "http://localhost:5001/api/v0/version", _, _) ->
                             %HTTPoison.Response{
                               status_code: 200,
                               body: "qwerty123"} end] do
      assert {:error, _err} = IPFS.Client.version
    end
  end

  test "HTTP error" do
    with_mock HTTPoison, [get!: fn(
                            "http://localhost:5001/api/v0/version", _, _) ->
                              %HTTPoison.Response{
                                status_code: 404,
                                body: "404 Not Found"} end] do
      assert {:error, _err} = IPFS.Client.version
    end
  end
end
