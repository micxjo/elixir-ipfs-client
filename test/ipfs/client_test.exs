defmodule ClientTest do
  use ExUnit.Case, async: true
  import Mock

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
end
