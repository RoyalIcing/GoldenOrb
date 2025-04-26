defmodule GoldenOrb.Plug do
  @behaviour Plug

  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    # put_resp_content_type(conn, "application/json")
    conn
  end

  @doc """
  The Orb module is compiled into a WebAssembly binary.
  """
  def send_wasm(conn, orb_module) do
    wasm = Orb.to_wasm(orb_module)

    conn
    |> Plug.Conn.put_resp_content_type("application/wasm", nil)
    |> Plug.Conn.send_resp(conn.status || 200, wasm)
  end

  @doc """
  The Orb module must implement the `text_html/0` function.
  """
  def send_html(conn, orb_module) do
    Protocol.assert_impl!(GoldenOrb.HTML, orb_module)

    # TODO: Use Wasmex to run the WebAssembly module and read the HTML string.

    conn
    |> Plug.Conn.put_resp_content_type("text/html")

    # |> Plug.Conn.send_resp(conn.status || 200, html)
  end

  @doc """
  The Orb module must implement the `image_svg_xml/0` function.
  """
  def send_svg(conn, orb_module) do
    Protocol.assert_impl!(GoldenOrb.SVG, orb_module)

    # TODO: Use Wasmex to run the WebAssembly module and read the SVG string.

    conn
    |> Plug.Conn.put_resp_content_type("image/svg+xml")
  end
end
