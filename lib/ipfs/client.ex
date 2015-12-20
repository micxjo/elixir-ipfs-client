defmodule IPFS.Client do
  @moduledoc """
  A client library for interacting with an IPFS node via its HTTP API.
  """
  defstruct host: "localhost", port: 5001

  @type port_number :: 0..65535
  @type t :: %__MODULE__{host: String.t, port: port_number}

  @doc ~S"""
  Create a new client pointing at the provided host and port.
  """
  @spec new(String.t, port_number) :: t
  def new(host, port) do
    %__MODULE__{host: host, port: port}
  end

  @doc ~S"""
  Get version details from the IPFS node.

  ## Examples

      iex> IPFS.Client.version
      %IPFS.Client.Version{version: "0.3.9", commit: "43622bs"}
  """
  @spec version(t) :: IPFS.Client.Version.t
  def version(client \\ %__MODULE__{}) do
    client
    |> request("version")
    |> IPFS.Client.Version.decode
  end

  @doc ~S"""
  Get a list of the set of peers the node is connected to.
  """
  @spec swarm_peers(t) :: [String.t]
  def swarm_peers(client \\ %__MODULE__{}) do
    client
    |> request("swarm/peers")
    |> Poison.decode!
    |> Map.get("Strings")
  end

  @doc ~S"""
  Get a list of known addresses.
  """
  @spec swarm_addrs(t) :: %{String.t => [String.t]}
  def swarm_addrs(client \\ %__MODULE__{}) do
    client
    |> request("swarm/addrs")
    |> Poison.decode!
    |> Map.get("Addrs")
  end

  @doc ~S"""
  Get a list of the node's local addresses.
  """
  @spec swarm_addrs_local(t) :: [String.t]
  def swarm_addrs_local(client \\ %__MODULE__{}) do
    client
    |> request("swarm/addrs/local")
    |> Poison.decode!
    |> Map.get("Strings")
  end

  @doc ~S"""
  Fetch a raw IPFS block.
  """
  @spec block_get(t, String.t) :: binary
  def block_get(client \\ %__MODULE__{}, key) do
    request(client, "block/get/#{key}")
  end

  @doc ~S"""
  Fetch an IPFS object.
  """
  @spec object_get(t, String.t) :: IPFS.Client.Object.t
  def object_get(client \\ %__MODULE__{}, key) do
    client
    |> request("object/get/#{key}")
    |> IPFS.Client.Object.decode
  end

  @doc ~S"""
  Retrieve information about an IPFS object.
  """
  @spec object_stat(t, String.t) :: IPFS.Client.ObjectStat.t
  def object_stat(client \\ %__MODULE__{}, key) do
    client
    |> request("object/stat/#{key}")
    |> IPFS.Client.ObjectStat.decode
  end

  @doc ~S"""
  Retrieve the node's local identity information.
  """
  @spec local_id(t) :: IPFS.Client.ID.t
  def local_id(client \\ %__MODULE__{}) do
    client
    |> request("id")
    |> IPFS.Client.ID.decode
  end

  @doc ~S"""
  Retrieve the identify information of a connected node.
  """
  @spec id(t, String.t) :: IPFS.Client.ID.t
  def id(client \\ %__MODULE__{}, peer_id) do
    client
    |> request("id/#{peer_id}")
    |> IPFS.Client.ID.decode
  end

  @doc ~S"""
  Retrieve the list of bootstrap peers.
  """
  @spec bootstrap_list(t) :: [String.t]
  def bootstrap_list(client \\ %__MODULE__{}) do
    client
    |> request("bootstrap/list")
    |> Poison.decode!
    |> Map.get("Peers")
  end

  @spec request(t, String.t) :: binary
  defp request(client, path) do
    url = make_url(client, path)
    %{status_code: 200, body: body} = HTTPoison.get!(url)
    body
  end

  @spec make_url(t, String.t) :: String.t
  defp make_url(%__MODULE__{host: host, port: port}, path) do
    "http://#{host}:#{port}/api/v0/#{path}"
  end
end

defmodule IPFS.Client.Version do
  @moduledoc """
  Version information of an IPFS node.
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
  A link to an IPFS object.
  """
  defstruct name: "", hash: "", size: 0

  @type t :: %IPFS.Client.Link{name: String.t,
                               hash: String.t,
                               size: non_neg_integer}

  @spec encode(t) :: binary
  def encode(%__MODULE__{name: name, hash: hash, size: size}) do
    Poison.encode!(%{"Name": name,
                     "Hash": hash,
                     "Size": size})
  end
end

defmodule IPFS.Client.Object do
  @moduledoc """
  An IPFS object.
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

  @spec encode(t) :: binary
  def encode(%__MODULE__{data: data, links: links}) do
    links = Enum.map(links, &IPFS.Client.Link.encode/1)
    Poison.encode!(%{"Data" => data,
                     "Links" => links})
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

defmodule IPFS.Client.ID do
  @moduledoc """
  Identity information about an IPFS peer.
  """
  defstruct [id: "", public_key: "", addresses: [], agent_version: "",
             protocol_version: ""]

  @type t :: %IPFS.Client.ID{
    id: String.t,
    public_key: String.t,
    addresses: [String.t],
    agent_version: String.t,
    protocol_version: String.t}

  @spec decode(binary) :: t
  def decode(json) do
    map = Poison.decode!(json)
    %IPFS.Client.ID{
      id: map["ID"],
      public_key: map["PublicKey"],
      addresses: map["Addresses"],
      agent_version: map["AgentVersion"],
      protocol_version: map["ProtocolVersion"]}
  end
end
