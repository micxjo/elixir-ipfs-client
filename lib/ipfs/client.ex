defmodule IPFS.Client do
  @moduledoc """
  A client library for interacting with an IPFS daemon.
  """
  defstruct host: "localhost", port: 5001

  @type port_number :: 0..65535
  @type t :: %__MODULE__{host: String.t, port: port_number}

  @doc ~S"""
  Request the IPFS server's version.

  ## Examples

      iex> IPFS.Client.version
      %IPFS.Client.Version{version: "0.3.9", commit: "43622bs"}
  """
  @spec version(t) :: IPFS.Client.Version.t
  def version(client \\ %__MODULE__{}) do
    %{status_code: 200, body: body} = HTTPoison.get!(
      make_url(client, "version"))
    IPFS.Client.Version.decode(body)
  end

  @spec swarm_peers(t) :: [String.t]
  def swarm_peers(client \\ %__MODULE__{}) do
    %{status_code: 200, body: body} = HTTPoison.get!(
      make_url(client, "swarm/peers"))
    Poison.decode!(body)["Strings"]
  end

  @spec make_url(t, String.t) :: String.t
  defp make_url(%__MODULE__{host: host, port: port}, path) do
    "http://#{host}:#{port}/api/v0/#{path}"
  end
end

defmodule IPFS.Client.Version do
  @moduledoc """
  A representation of an IPFS server version.
  """
  defstruct version: "0.0", commit: "0"

  @type t :: %__MODULE__{version: String.t, commit: String.t}

  @spec decode(binary) :: t
  def decode(json) do
    %{"Version" => version, "Commit" => commit} = Poison.decode!(json)
    %__MODULE__{version: version, commit: commit}
  end
end
