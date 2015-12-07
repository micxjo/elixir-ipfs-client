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

  @spec swarm_addrs(t) :: %{String.t => [String.t]}
  def swarm_addrs(client \\ %__MODULE__{}) do
    %{status_code: 200, body: body} = HTTPoison.get!(
      make_url(client, "swarm/addrs"))
    Poison.decode!(body)["Addrs"]
  end

  @spec block_get(t, String.t) :: binary
  def block_get(client \\ %__MODULE__{}, key) do
    %{status_code: 200, body: body} = HTTPoison.get!(
      make_url(client, "block/get/#{key}"))
    body
  end

  @spec object_get(t, String.t) :: IPFS.Client.Object.t
  def object_get(client \\ %__MODULE__{}, key) do
    %{status_code: 200, body: body} = HTTPoison.get!(
      make_url(client, "object/get/#{key}"))
    IPFS.Client.Object.decode(body)
  end

  @spec object_stat(t, String.t) :: IPFS.Client.ObjectStat.t
  def object_stat(client \\ %__MODULE__{}, key) do
    %{status_code: 200, body: body} = HTTPoison.get!(
      make_url(client, "object/stat/#{key}"))
    IPFS.Client.ObjectStat.decode(body)
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

defmodule IPFS.Client.Link do
  @moduledoc """
  Represents a link to an IPFS object.
  """
  defstruct name: "", hash: "", size: 0

  @type t :: %IPFS.Client.Link{name: String.t,
                               hash: String.t,
                               size: non_neg_integer}
end

defmodule IPFS.Client.Object do
  @moduledoc """
  Represents an IPFS object.
  """
  defstruct links: [], data: <<>>

  @type t :: %IPFS.Client.Object{links: [IPFS.Client.Link.t], data: binary}

  @spec decode(binary) :: t
  def decode(json) do
    map = Poison.decode!(json)
    links = map["Links"]
    |> Enum.map(fn l -> %IPFS.Client.Link{name: l["Name"],
                                          hash: l["Hash"],
                                          size: l["Size"]} end)
    %IPFS.Client.Object{data: map["Data"], links: links}
  end
end

defmodule IPFS.Client.ObjectStat do
  @moduledoc """
  Information about an IPFS object.
  """
  defstruct [hash: "", num_links: 0, block_size: 0,
             links_size: 0, data_size: 0, cumulative_size: 0]

  @type t :: %IPFS.Client.ObjectStat{
    hash: String.t,
    num_links: non_neg_integer,
    block_size: non_neg_integer,
    links_size: non_neg_integer,
    data_size: non_neg_integer,
    cumulative_size: non_neg_integer}

  @spec decode(binary) :: t
  def decode(json) do
    map = Poison.decode!(json)
    %IPFS.Client.ObjectStat{
      hash: map["Hash"],
      num_links: map["NumLinks"],
      block_size: map["BlockSize"],
      links_size: map["LinksSize"],
      data_size: map["DataSize"],
      cumulative_size: map["CumulativeSize"]}
  end
end
