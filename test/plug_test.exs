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

  defmodule CSSTheme do
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
      value = %CSSTheme{}
      conn = GoldenOrb.Plug.send_css(conn, value)

      assert get_resp_header(conn, "content-type") == ["text/css; charset=utf-8"]

      assert conn.resp_body == """
             body { background-color: white; text: black; }
             """
    end

    test "when theme is hot_dog_stand", %{conn: conn} do
      value = %CSSTheme{theme: :hot_dog_stand}
      conn = GoldenOrb.Plug.send_css(conn, value)

      assert get_resp_header(conn, "content-type") == ["text/css; charset=utf-8"]

      assert conn.resp_body == """
             body { background-color: red; text: yellow; }
             """
    end
  end

  defmodule JSDynamicTitle do
    use Orb

    defstruct silly?: false

    export do
      global I32, :mutable do
        @silly? 0
      end
    end

    defw text_javascript(), Str do
      if @silly?, result: Str do
        """
        document.title = "Welcome to Prestige Worldwide 🛥️🎶";
        """
      else
        """
        document.title = "Welcome to my website";
        """
      end
    end
  end

  describe "send_javascript/2" do
    test "when default", %{conn: conn} do
      value = %JSDynamicTitle{}
      conn = GoldenOrb.Plug.send_javascript(conn, value)

      assert get_resp_header(conn, "content-type") == ["text/javascript; charset=utf-8"]

      assert conn.resp_body == """
             document.title = "Welcome to my website";
             """
    end

    test "when silly? is true", %{conn: conn} do
      value = %JSDynamicTitle{silly?: true}
      conn = GoldenOrb.Plug.send_javascript(conn, value)

      assert get_resp_header(conn, "content-type") == ["text/javascript; charset=utf-8"]

      assert conn.resp_body == """
             document.title = "Welcome to Prestige Worldwide 🛥️🎶";
             """
    end
  end

  defmodule HTMLLayout do
    use Orb

    defstruct lang: :en

    export do
      global I32, :mutable do
        @lang 0
      end
    end

    defw(lang_en(), I32, do: :en)
    defw(lang_es(), I32, do: :es)

    defw html_attributes(), Str do
      if @lang === const(:es), result: Str do
        ~S|lang="es"|
      else
        ~S|lang="en"|
      end
    end

    defw html_head(), Str do
      if @lang === const(:es), result: Str do
        """
        <title>Hola Mundo</title>
        """
      else
        """
        <title>Hello World</title>
        """
      end
    end

    defw html_body(), Str do
      if @lang === const(:es), result: Str do
        """
        <body>
        <h1>Hola Mundo</h1>
        """
      else
        """
        <body>
        <h1>Hello World</h1>
        """
      end
    end
  end

  defmodule PrimaryNav do
    use Orb

    defstruct []

    defw html_head_content(), Str do
      ""
    end

    defw html_body_content(), Str do
      """
      <nav aria-label="Primary">
        <a href="/">Home</a>
        <a href="/about">About</a>
      </nav>
      """
    end
  end

  describe "send_html/2" do
    test "when default", %{conn: conn} do
      value = %HTMLLayout{lang: :en}
      conn = GoldenOrb.Plug.send_html(conn, value)

      assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]

      assert conn.resp_body == """
             <!DOCTYPE html><html lang="en"><meta charset=utf-8>
             <title>Hello World</title>
             <body>
             <h1>Hello World</h1>
             """
    end

    test "when silly? is true", %{conn: conn} do
      value = %HTMLLayout{lang: :es}
      conn = GoldenOrb.Plug.send_html(conn, value)

      assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]

      assert conn.resp_body == """
             <!DOCTYPE html><html lang="es"><meta charset=utf-8>
             <title>Hola Mundo</title>
             <body>
             <h1>Hola Mundo</h1>
             """
    end
  end

  describe "send_html/3" do
    # We have 4 WebAssembly modules: HTMLLayout, CSSTheme, JSDynamicTitle, PrimaryNav. The HTML one acts as the layout providing the base html. The CSS renders the inline stylesheet. The JS renders the inline ES module. The PrimaryNav renders the <nav>. These interleave with body content from the layout.
    test "html + css + js", %{conn: conn} do
      conn =
        GoldenOrb.html(conn, %HTMLLayout{lang: :es}, [
          %CSSTheme{theme: :hot_dog_stand},
          %JSDynamicTitle{silly?: true},
          %PrimaryNav{}
        ])

      assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]

      assert conn.resp_body == """
             <!DOCTYPE html><html lang="es"><meta charset=utf-8>
             <title>Hola Mundo</title>
             <style>
             body { background-color: red; text: yellow; }
             </style>
             <script type="module">
             document.title = &quot;Welcome to Prestige Worldwide 🛥️🎶&quot;;
             </script>
             <body>
             <h1>Hola Mundo</h1>
             <nav aria-label="Primary">
               <a href="/">Home</a>
               <a href="/about">About</a>
             </nav>
             """
    end
  end
end
