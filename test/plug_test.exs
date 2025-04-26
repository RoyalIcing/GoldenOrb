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

    defstruct theme: :default

    export do
      global I32, :mutable do
        @theme 0
      end
    end

    defw(theme_default(), I32, do: 0)
    defw(theme_hot_dog_stand(), I32, do: :hot_dog_stand)

    defw text_css(), Str do
      if @theme === const(:hot_dog_stand), result: Str do
        """
        body { background-color: red; text: yellow; }
        """
      else
        """
        body { background-color: white; text: black; }
        """
      end
    end
  end

  describe "send_css/2" do
    test "when theme is default", %{conn: conn} do
      value = %CSSExample{}
      conn = GoldenOrb.Plug.send_css(conn, value)

      assert get_resp_header(conn, "content-type") == ["text/css; charset=utf-8"]

      assert conn.resp_body == """
             body { background-color: white; text: black; }
             """
    end

    test "when theme is hot_dog_stand", %{conn: conn} do
      value = %CSSExample{theme: :hot_dog_stand}
      conn = GoldenOrb.Plug.send_css(conn, value)

      assert get_resp_header(conn, "content-type") == ["text/css; charset=utf-8"]

      assert conn.resp_body == """
             body { background-color: red; text: yellow; }
             """
    end
  end
end
