defmodule PlugTest do
  use GoldenOrb.ConnCase

  defmodule Example do
    use Orb

    defw magic_number(), I32 do
      42
    end
  end

  test "send_wasm/2", %{conn: conn} do
    conn = GoldenOrb.Plug.send_wasm(conn, Example)

    assert get_resp_header(conn, "content-type") == ["application/wasm"]
    assert conn.resp_body =~ "\0asm\x01\0\0\0"
    assert conn.resp_body =~ "magic_number"
    assert conn.resp_body =~ <<42>>
  end

  defmodule CSSExample do
    use Orb

    defstruct []

    defw text_css(), Str do
      "body { background-color: #000; }"
    end

    # defimpl GoldenOrb.CSS do
    #   def text_css(_context) do
    #     wat = Orb.to_wat(@for)
    #     {:ok, pid} = Wasmex.start_link(%{bytes: wat})
    #     {:ok, memory} = Wasmex.memory(pid)
    #     {:ok, store} = Wasmex.store(pid)

    #     call_function = &Wasmex.call_function(pid, &1, &2)
    #     read_binary = &Wasmex.Memory.read_binary(store, memory, &1, &2)

    #     {:ok, [ptr, size]} = call_function.(:text_css, [])
    #     text = read_binary.(ptr, size)
    #     text
    #   end
    # end
  end

  test "text_css/1", %{conn: conn} do
    # Protocol.consolidate(GoldenOrb.CSS, [CSSExample])

    value = %CSSExample{}
    conn = GoldenOrb.Plug.send_css(conn, value)

    assert get_resp_header(conn, "content-type") == ["text/css; charset=utf-8"]
    assert conn.resp_body == "body { background-color: #000; }"
  end
end
