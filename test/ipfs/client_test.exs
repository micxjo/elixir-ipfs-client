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
end
