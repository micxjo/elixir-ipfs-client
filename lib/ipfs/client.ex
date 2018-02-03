defmodule IPFS.Client do
  @moduledoc """
  A client library for interacting with an IPFS node via its HTTP API.
  """
  @user_agent "/elixir-ipfs-client/0.0.1/"

  defstruct [host: "localhost", port: 5001,
             user_agent: @user_agent]

  @typedoc "A TCP port"
  @type port_number :: 0..65535

  @typedoc "A connection to an IPFS node"
  @type t :: %__MODULE__{host: String.t, port: port_number,
                         user_agent: String.t}

  @doc ~S"""
  Creates a new client pointing at the provided host and port.

  ## Example

      iex> IPFS.Client.new("localhost", 5002)
      %IPFS.Client{host: "localhost", port: 5002}
  """
  @spec new(String.t, port_number) :: t
  def new(host, port) do
    %__MODULE__{host: host, port: port}
  end

  @doc ~S"""
  Gets version details from the IPFS node.

  ## Example

      iex> IPFS.Client.version
      {:ok, %IPFS.Client.Version{version: "0.3.9", commit: "43622bs"}}
  """
  @spec version(t) :: {:ok, IPFS.Client.Version.t} | {:error, any}
  def version(client \\ %__MODULE__{}) do
    client
    |> request("version")
    |> IPFS.Client.Version.decode
  end

  @doc ~S"""
  Gets the list of peers that the node is connected to.

  ## Example

      iex> IPFS.Client.swarm_peers
      {:ok, ["/ip4/104.131.131.82/tcp/4001/ipfs/QmaCpDMGvV2BGHeYERUEnRQ",
            "/ip4/104.236.176.52/tcp/4001/ipfs/QmSoLnSGccFuZQJzRadHn95W",
            "/ip4/104.236.151.122/tcp/4001/ipfs/QmSoLju6m7xTh3DuokvT388"]}
  """
  @spec swarm_peers(t) :: {:ok, [String.t]} | {:error, any}
  def swarm_peers(client \\ %__MODULE__{}) do
    case client |> request("swarm/peers") |> decode do
      {:ok, map} -> {:ok, Map.get(map, "Strings")}
      other -> other
    end
  end

  @doc ~S"""
  Gets a list of known addresses.

  ## Example

      iex> IPFS.Client.swarm_addrs
      {:ok, %{"QmNRCEwFMgCcbjNk5bFud9oqjJduvjBNbkiM8SuxuLh3GS" =>
               ["/ip4/127.0.0.1/tcp/4001",
                "/ip4/172.17.42.1/tcp/4001",
                "/ip4/192.168.2.3/tcp/4001",
                "/ip6/::1/tcp/4001"],
              "QmNRV7kyUxYaQ4KQxFXPYm8EfuzJbtGn1wSFenjXL6LD8y" =>
               ["/ip4/127.0.0.1/tcp/4001",
                "/ip6/2a01:4f8:161:124a::1337:cafe/tcp/4001"]}}
  """
  @spec swarm_addrs(t) :: {:ok, %{String.t => [String.t]}} | {:error, any}
  def swarm_addrs(client \\ %__MODULE__{}) do
    case client |> request("swarm/addrs") |> decode do
      {:ok, map} -> {:ok, Map.get(map, "Addrs")}
      other -> other
    end
  end

  @doc ~S"""
  Gets a list of the node's local addresses.

  ## Example

      iex> IPFS.Client.swarm_addrs_local
      {:ok, ["/ip4/127.0.0.1/tcp/4001",
             "/ip4/192.168.1.2/tcp/4001",
             "/ip6/::1/tcp/4001"]
  """
  @spec swarm_addrs_local(t) :: {:ok, [String.t]} | {:error, any}
  def swarm_addrs_local(client \\ %__MODULE__{}) do
    case client |> request("swarm/addrs/local") |> decode do
      {:ok, map} -> {:ok, Map.get(map, "Strings")}
      other -> other
    end
  end

  @doc ~S"""
  Gets a raw IPFS block.

  ## Example

       iex> IPFS.Client.block_get("QmaCsr3YEv2BAwe")
       {:ok, <<0, 1, 2, 3, 4>>}
  """
  @spec block_get(t, String.t) :: {:ok, binary} | {:error, any}
  def block_get(client \\ %__MODULE__{}, key) do
    request(client, "block/get/#{key}")
  end

  @doc ~S"""
  Gets an IPFS object.

  ## Example

      iex> IPFS.Client.object_get("QmdoDatULjkor1eA1YhBAjmKkkD")
      {:ok, %IPFS.Client.Object{hash: "QmdoDatULjkor1eA1YhBAjmKkkD",
                                links: [%IPFS.Client.Link{hash: "QmaSf39sCs",
                                                          name: "index.html",
                                                          size: 262158}]}}
  """
  @spec object_get(t, String.t) :: {:ok, IPFS.Client.Object.t} | {:error, any}
  def object_get(client \\ %__MODULE__{}, key) do
    client
    |> request("object/get/#{key}")
    |> IPFS.Client.Object.decode
  end

  @doc ~S"""
  Gets an IPFS object encoded as protobuf.

  ## Example

      iex> IPFS.Client.object_get_protobuf("QmdoDatULjkor1eA1YhBAjmKkkD")
      {:ok, <<18, 48, 10, 34, 18, 32, 66, 250, 4, 91, 202, 123, 233, 191, 30, 73, 233, 44,
              203, 227, 31, 228, 160, 154, 224, 224, 171, 88, 211, 240, 192, 97, 145, 36,
              144, 151, 166, 88, 18, 7, 107, 105, 116, 116, 101, 110, 115, 24, 155, 1, 18,
              47, 10, 34, 18, 32, 8, 209, 87, 57, 117, 200, 175, 129, 190, 191, 5, 128, 11,
              71, 179, 236, 133, 83, 51, 227, 180, 158, 218, 82, 202, 49, 165, 170, 154, 20,
              171, 221, 18, 7, 111, 114, 112, 104, 97, 110, 115, 24, 42, 10, 2, 8, 1>>}
  """
  @spec object_get_protobuf(t, String.t) :: {:ok, binary()} | {:error, any}
  def object_get_protobuf(client \\ %__MODULE__{}, key) do
    client
    |> request("object/get/#{key}", [], [encoding: "protobuf"])
  end

  @doc ~S"""
  Creates a new object.

  # TODO: Add template

  ## Example

      iex> IPFS.Client.object_new()
      {:ok, %IPFS.Client.PatchObject{hash: "QmUvYWLEr3pM8xGFLdEfmGhpHz6VTAkh8Aom3ucC62uGsK"
                                links: []}}
  """
  @spec object_new(t) :: {:ok, IPFS.Client.Object.t} | {:error, any}
  def object_new(client \\ %__MODULE__{}) do
    client
    |> request("object/new")
    |> IPFS.Client.PatchObject.decode
  end

  @doc ~S"""
  Puts a new object.

  ## Example

      iex> IPFS.Client.object_put("test data", false)
      {:ok, %IPFS.Client.PatchObject{hash: "QmUvYWLEr3pM8xGFLdEfmGhpHz6VTAkh8Aom3ucC62uGsK",
                                links: []}}
  """
  @spec object_put(t, String.t) :: {:ok, IPFS.Client.Object.t} | {:error, any}
  def object_put(client \\ %__MODULE__{}, data, pin) do
    client
    |> request_post("object/put", [data: %{"Data" => data |> Base.encode64} |> Poison.encode!], [datafieldenc: "base64", pin: pin |> to_string])
    |> IPFS.Client.PatchObject.decode
  end

  @doc ~S"""
  Patches an object with a new link.

  ## Example

      iex> IPFS.Client.object_patch_add_link("QmaSf39sCs", "/names/1", "QmdoDatULjkor1eA1YhBAjmKkkD", true)
      {:ok, %IPFS.Client.PatchObject{hash: <<39, 42, 19, 1>>,
                                links: [%IPFS.Client.Link{hash: "QmdoDatULjkor1eA1YhBAjmKkkD",
                                                          name: "/names/1",
                                                          size: 10}]}}
  """
  @spec object_patch_add_link(t, binary(), String.t, boolean()) :: {:ok, IPFS.Client.Object.t} | {:error, any}
  def object_patch_add_link(client \\ %__MODULE__{}, hash, link_name, link_hash, create_intermediary) do
    client
    |> request("object/patch/add-link", [hash, link_name, link_hash], create: create_intermediary |> to_string)
    |> IPFS.Client.PatchObject.decode
  end

  @doc ~S"""
  Gets information about an IPFS object (DAG node).

  ## Example

      iex> IPFS.Client.object_stat("QmdoDatULjkor1eA1YhBAjmKkkD")
      {:ok, %IPFS.Client.ObjectStat{block_size: 777,
                                    cumulative_size: 394284,
                                    data_size: 71,
                                    links_size: 706,
                                    num_links: 16,
                                    hash: "QmdoDatULjkor1eA1YhBAjmKkkD"}}
  """
  @spec (object_stat(t, String.t) ::
         {:ok, IPFS.Client.ObjectStat.t} | {:error, any})
  def object_stat(client \\ %__MODULE__{}, key) do
    client
    |> request("object/stat/#{key}")
    |> IPFS.Client.ObjectStat.decode
  end

  @doc ~S"""
  Gets the node's local identity information.

  ## Example

      iex> IPFS.Client.local_id
      {:ok, %IPFS.Client.ID{
              id: "QmNRCEwFMgCcbjNk5bFud",
              public_key: "CAASpVCHJYVmkqSAQ",
              addresses: [
                "/ip6/::1/tcp/4001/QmNRCEwFMgCcbjNk5bFud",
                "/ip4/127.0.0.1/tcp/4001/ipfs/QmNRCEwFMgCcbjNk5bFud"],
              agent_version: "go-ipfs/0.3.11-dev",
              protocol_version: "ipfs/0.1.0"}}
  """
  @spec local_id(t) :: {:ok, IPFS.Client.ID.t} | {:error, any}
  def local_id(client \\ %__MODULE__{}) do
    client
    |> request("id")
    |> IPFS.Client.ID.decode
  end

  @doc ~S"""
  Gets the identify information of a connected node.

  ## Example

      iex> IPFS.Client.id("QmNRCEwFMgCcbjNk5bFud")
      {:ok, %IPFS.Client.ID{
              id: "QmNRCEwFMgCcbjNk5bFud",
              public_key: "CAASpVCHJYVmkqSAQ",
              addresses: [
                "/ip6/::1/tcp/4001/QmNRCEwFMgCcbjNk5bFud",
                "/ip4/127.0.0.1/tcp/4001/ipfs/QmNRCEwFMgCcbjNk5bFud"],
              agent_version: "go-ipfs/0.3.11-dev",
              protocol_version: "ipfs/0.1.0"}}
  """
  @spec id(t, String.t) :: {:ok, IPFS.Client.ID.t} | {:error, any}
  def id(client \\ %__MODULE__{}, peer_id) do
    client
    |> request("id/#{peer_id}")
    |> IPFS.Client.ID.decode
  end

  @doc ~S"""
  Gets the list of bootstrap peers.

  ## Example

      iex> IPFS.Client.bootstrap_list
      {:ok, ["/ip4/104.131.131.82/tcp/4001/ipfs/QmaCpDMGvV2BGHeY",
             "/ip4/104.236.176.52/tcp/4001/ipfs/QmSoLnSGccFuZQJz",
             "/ip4/104.236.179.241/tcp/4001/ipfs/QmSoLPppuBtQSGw"]}
  """
  @spec bootstrap_list(t) :: {:ok, [String.t]} | {:error, any}
  def bootstrap_list(client \\ %__MODULE__{}) do
    case client |> request("bootstrap/list") |> decode do
      {:ok, map} -> {:ok, Map.get(map, "Peers")}
      other -> other
    end
  end

  @doc ~S"""
  Gets a list of the objects pinned to local storage.

  ## Example

      iex> IPFS.Client.pin_ls
      {:ok, [%IPFS.Client.Pin{hash: "QmPZ9gcCEpqKTo6aq61g2nXGUhM4i",
                              count: 1,
                              type: "recursive"},
             %IPFS.Client.Pin{hash: "QmTumTjvcYCAvRRwQ8sDRxh8ezmrc",
                              count: 3,
                              type: "direct"}]}
  """
  @spec pin_ls(t) :: {:ok, [IPFS.Client.Pin.t]} | {:error, any}
  def pin_ls(client \\ %__MODULE__{}) do
    case client |> request("pin/ls") |> decode do
      {:ok, map} ->
        {:ok,
         map
         |> Map.get("Keys")
         |> Enum.map(&IPFS.Client.Pin.decode/1)}
      other -> other
    end
  end

  @doc ~S"""
  Publishes a hash to IPNS, which is mutable storage.

  Note: this is a slower operation and may take some time.

  ## Example

      iex> IPFS.Client.name_publish(%__MODULE__{}, "QmPZ9gcCEpqKTo6aq61g2nXGUhM4i")
      {:ok, %IPFS.Client.Published{
        name: "QmTUESDMNR1Nmf6BzwSFBSRDG6H59PmH1CY4Jx22F3S9TV",
        value: "/ipfs/QmNgGKjCpUTqnoiTFVERnEhQpv9c2wsbHExMUFxzvRGYca"
      }}
  """
  @type publish_opts :: [resolve: boolean(), lifetime: String.t, ttl: integer(), key: String.t]
  @spec name_publish(t, binary(), publish_opts) :: {:ok, IPFS.Client.Published.t} | {:error, any()}
  def name_publish(client \\ %__MODULE__{}, hash, opts \\ []) do
    request_params = []
      |> maybe_put_param(opts, :resolve)
      |> maybe_put_param(opts, :lifetime)
      |> maybe_put_param(opts, :ttl)
      |> maybe_put_param(opts, :key)
    timeout = Keyword.get(opts, :timeout, 60_000)

    request(client, "name/publish", [hash], request_params, timeout)
    |> IPFS.Client.Published.decode()
  end

  @doc ~S"""
  Publishes a hash to IPNS, which is mutable storage.

  ## Example

      iex> IPFS.Client.name_resolve(%__MODULE__{}, "QmPZ9gcCEpqKTo6aq61g2nXGUhM4i")
      {:ok, %IPFS.Client.Published{
        value: "/ipfs/QmNgGKjCpUTqnoiTFVERnEhQpv9c2wsbHExMUFxzvRGYca"
      }}
  """
  @type resolve_opts :: [recursive: boolean(), nocache: boolean(), timeout: integer()]
  @spec name_resolve(t, binary() | nil, resolve_opts) :: {:ok, IPFS.Client.Published.t} | {:error, any()}
  def name_resolve(client \\ %__MODULE__{}, name \\ nil, opts \\ []) do
    request_params = []
      |> maybe_put_param(opts, :recursive)
      |> maybe_put_param(opts, :nocache)
    args = if name, do: [name], else: []
    timeout = Keyword.get(opts, :timeout, 60_000)

    request(client, "name/resolve", args, request_params, timeout)
    |> IPFS.Client.Published.decode()
  end

  @doc ~S"""
  Generates a new key.

  ## Example

      iex> IPFS.Client.key_gen(%__MODULE__{}, "my_key", [type: "rsa", size: 3072])
      {:ok, %IPFS.Client.Key{
        name: "my_key",
        id: "key_id"
      }}
  """
  @type key_opts :: [type: String.t, size: integer()]
  @spec key_gen(t, String.t, key_opts) :: {:ok, IPFS.Client.Key.t} | {:error, any()}
  def key_gen(client \\ %__MODULE__{}, name, key_opts \\ []) do
    type = Keyword.get(key_opts, :type, "rsa")
    size = Keyword.get(key_opts, :size, 3072)

    request(client, "key/gen", [name], [type: type, size: size])
    |> IPFS.Client.Key.decode()
  end

  @spec maybe_put_param([], keyword(), atom()) :: []
  defp maybe_put_param(params, opts, key) do
    if value = Keyword.get(opts, key) do
      params ++ [{key |> to_string, value}]
    else
      params
    end
  end

  @spec request(t, String.t, [String.t], keyword()) :: {:ok, binary} | {:error, any}
  defp request(client, path, args \\ [], params \\ [], timeout \\ 5000) do
    url = make_url(client, path)
    ua = Map.get(client, :user_agent, @user_agent)
    arg_params = for arg <- args, do: {"arg", arg}
    case HTTPoison.get!(url, [{"User-agent", ua}], params: arg_params ++ params, timeout: timeout, recv_timeout: timeout) do
      %{status_code: 200, body: body} -> {:ok, body}
      other -> {:error, other}
    end
  end

  @spec request_post(t, String.t, keyword(), keyword()) :: {:ok, binary} | {:error, any}
  defp request_post(client, path, form_data, params \\ []) do
    url = make_url(client, path)
    ua = Map.get(client, :user_agent, @user_agent)
    form = for {k, v} <- form_data do
      {k |> to_string, v}
    end
    case HTTPoison.post!(url, {:multipart, form}, [{"User-agent", ua}], params: params) do
      %{status_code: 200, body: body} -> {:ok, body}
      other -> {:error, other}
    end
  end

  @spec decode({:ok, binary} | {:error, any}) :: {:ok, %{}} | {:error, any}
  defp decode({:ok, json}) do
    Poison.decode(json)
  end

  defp decode(other), do: other

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

  @doc false
  @spec decode({:ok, binary} | {:error, any}) :: {:ok, t} | {:error, any}
  def decode({:ok, json}) do
    case Poison.decode(json) do
      {:ok, %{"Version" => version, "Commit" => commit}} ->
        {:ok, %__MODULE__{version: version, commit: commit}}
      {:error, err} -> {:error, err}
      _other -> {:error, :missing_fields}
    end
  end

  def decode(other), do: other
end

defmodule IPFS.Client.Link do
  @moduledoc """
  A link to an IPFS object.
  """
  defstruct name: "", hash: "", size: 0

  @type t :: %IPFS.Client.Link{name: String.t,
                               hash: String.t,
                               size: non_neg_integer}

  @doc false
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

  @doc false
  @spec decode({:ok, binary} | {:error, any}) :: {:ok, t} | {:error, any}
  def decode({:ok, json}) do
    case Poison.decode(json) do
      {:ok, map} ->
        links = map["Links"] |>
          Enum.map(fn l -> %IPFS.Client.Link{name: l["Name"],
                                            hash: l["Hash"],
                                            size: l["Size"]} end)
        {:ok, %IPFS.Client.Object{data: map["Data"], links: links}}
      other -> other
    end
  end

  def decode(other), do: other

  @doc false
  @spec encode(t) :: binary
  def encode(%__MODULE__{data: data, links: links}) do
    links = Enum.map(links, &IPFS.Client.Link.encode/1)
    Poison.encode!(%{"Data" => data,
                     "Links" => links})
  end
end

defmodule IPFS.Client.PatchObject do
  @moduledoc """
  An IPFS new object.
  """
  defstruct hash: <<>>, links: []

  @type t :: %IPFS.Client.PatchObject{hash: binary, links: [IPFS.Client.Link.t]}

  @doc false
  @spec decode({:ok, binary} | {:error, any}) :: {:ok, t} | {:error, any}
  def decode({:ok, json}) do
    case Poison.decode(json) do
      {:ok, map} ->
        links = (map["Links"] || []) |>
          Enum.map(fn l -> %IPFS.Client.Link{name: l["Name"],
                                            hash: l["Hash"],
                                            size: l["Size"]} end)
        {:ok, %IPFS.Client.PatchObject{hash: map["Hash"], links: links}}
      other -> other
    end
  end

  def decode(other), do: other

  @doc false
  @spec encode(t) :: binary
  def encode(%__MODULE__{hash: hash, links: links}) do
    links = Enum.map(links, &IPFS.Client.Link.encode/1)
    Poison.encode!(%{"Hash" => hash,
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

  @doc false
  @spec decode({:ok, binary} | {:error, any}) :: {:ok, t} | {:error, any}
  def decode({:ok, json}) do
    case Poison.decode(json) do
      {:ok, map} ->
        {:ok, %IPFS.Client.ObjectStat{
            hash: map["Hash"],
            num_links: map["NumLinks"],
            block_size: map["BlockSize"],
            links_size: map["LinksSize"],
            data_size: map["DataSize"],
            cumulative_size: map["CumulativeSize"]}}
      other -> other
    end
  end

  def decode(other), do: other
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

  @doc false
  @spec decode({:ok, binary} | {:error, any}) :: {:ok, t} | {:error, any}
  def decode({:ok, json}) do
    case Poison.decode(json) do
      {:ok, map} ->
        {:ok, %IPFS.Client.ID{
            id: map["ID"],
            public_key: map["PublicKey"],
            addresses: map["Addresses"],
            agent_version: map["AgentVersion"],
            protocol_version: map["ProtocolVersion"]}}
      other -> other
    end
  end

  def decode(other), do: other
end

defmodule IPFS.Client.Pin do
  @moduledoc """
  Information about an object pinned to local storage.
  """
  defstruct [hash: "", type: "recursive", count: 1]

  @type t :: %IPFS.Client.Pin{
    hash: String.t,
    type: String.t,
    count: non_neg_integer}

  @doc false
  @spec decode({String.t, %{}}) :: t
  def decode({k, v}) do
    %__MODULE__{hash: k,
                type: Map.get(v, "Type"),
                count: Map.get(v, "Count")}
  end
end

defmodule IPFS.Client.Published do
  @moduledoc """
  Information about an object which has been published
  """
  defstruct [name: nil, value: ""]

  @type t :: %IPFS.Client.Published{
    name: String.t,
    value: String.t
  }

  @doc false
  @spec decode({:ok, binary()} | {:error, any()}) :: {:ok, t} | {:error, any()}
  def decode({:ok, json}) do
    case Poison.decode(json) do
      {:ok, map} ->
        {:ok, %__MODULE__{
          name: map["Name"],
          value: map["Value"] || map["Path"]
        }}
      other -> other
    end
  end

  def decode(other), do: other
end

defmodule IPFS.Client.Key do
  @moduledoc """
  Information about an IPFS key.
  """
  defstruct [name: "", id: ""]

  @type t :: %IPFS.Client.Key{
    name: String.t,
    id: String.t
  }

  @doc false
  @spec decode({:ok, binary()} | {:error, any()}) :: {:ok, t} | {:error, any()}
  def decode({:ok, json}) do
    case Poison.decode(json) do
      {:ok, map} ->
        {:ok, %__MODULE__{
          name: map["Name"],
          id: map["Id"]
        }}
      other -> other
    end
  end

  def decode(other), do: other
end