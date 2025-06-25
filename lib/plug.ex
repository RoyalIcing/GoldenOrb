defmodule GoldenOrb.Plug do
  @moduledoc """
  Renders Orb modules and serves them over HTTP.
  """

  @behaviour Plug

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    # put_resp_content_type(conn, "application/json")
    conn
  end

  @doc """
  Serves a WebAssembly binary compiled from the passed Orb module.
  """
  def send_wasm(conn, orb_module) do
    wasm = Orb.to_wasm(orb_module)

    conn
    |> Plug.Conn.put_resp_content_type("application/wasm", nil)
    |> Plug.Conn.send_resp(conn.status || 200, wasm)
  end

  @doc """
  The `document` Orb module must implement the `html_attributes/0`, `html_head/0`, `html_body/0` functions.
  """
  def send_html(conn, document, fragments \\ []) do
    # Protocol.assert_impl!(GoldenOrb.HTML, orb_module)

    html_source = GoldenOrb.HTML.text_html(document, fragments)

    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> Plug.Conn.send_resp(conn.status || 200, html_source)
  end

  @doc """
  Your Orb module must implement the `GoldenOrb.CSS` protocol and the `text_css/0` wasm function.
  """
  def send_css(conn, struct) do
    css_source = GoldenOrb.CSS.text_css(struct)

    conn
    |> Plug.Conn.put_resp_content_type("text/css")
    |> Plug.Conn.send_resp(conn.status || 200, css_source)
  end

  @doc """
  Your Orb module must implement the `GoldenOrb.JavaScript` protocol and the `text_javascript/0` wasm function.
  """
  def send_javascript(conn, struct) do
    js_source = GoldenOrb.JavaScript.text_javascript(struct)

    conn
    |> Plug.Conn.put_resp_content_type("text/javascript")
    |> Plug.Conn.send_resp(conn.status || 200, js_source)
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
