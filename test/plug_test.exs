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

    defstruct dark?: false

    export do
      global I32, :mutable do
        @dark? 0
      end
    end

    defw text_css(), Str do
      if @dark?, result: Str do
        """
        body { background-color: white; text: black; }
        """
      else
        """
        body { background-color: black; text: white; }
        """
      end
    end
  end

  describe "send_css/2" do
    test "when dark? is false", %{conn: conn} do
      value = %CSSExample{dark?: false}
      conn = GoldenOrb.Plug.send_css(conn, value)

      assert get_resp_header(conn, "content-type") == ["text/css; charset=utf-8"]

      assert conn.resp_body == """
             body { background-color: black; text: white; }
             """
    end

    test "when dark? is true", %{conn: conn} do
      value = %CSSExample{dark?: true}
      conn = GoldenOrb.Plug.send_css(conn, value)

      assert get_resp_header(conn, "content-type") == ["text/css; charset=utf-8"]

      assert conn.resp_body == """
             body { background-color: white; text: black; }
             """
    end
  end
end
