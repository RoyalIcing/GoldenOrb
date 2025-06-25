defmodule PlugFormTest do
  use GoldenOrb.ConnCase

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
      """
      <title>Search</title>
      """
    end

    defw html_body(), Str do
      """
      <body>
      """
    end
  end

  defmodule ViewTransitions do
    use Orb

    defstruct []

    defw html_head_content(), Str do
      """
      <style>
      @view-transition { navigation: auto }
      </style>
      """
    end
  end

  defmodule SearchForm do
    use Orb

    defstruct [:q]

    defw html_body_content(), Str do
      """
      <form>
        <input name="q" placeholder="Search">
      </form>
      """
    end
  end

  defmodule Write do
    use Orb

    def write!(string, write!, write_size!) when is_binary(string) do
      read_size = byte_size(string)

      Orb.snippet do
        # use Orb.DSL
        # use Orb.Numeric.DSL

        assert!(write_size!.read >= read_size)
        Memory.copy!(write!.read, Orb.DSL.const(string).memory_offset, read_size)
        Orb.MutRef.store(write!, write!.read + read_size)
        Orb.MutRef.store(write_size!, write_size!.read - read_size)
      end
    end
  end

  defmodule NavLink do
    use Orb
    defstruct current_page?: false

    export do
      global I32, :mutable do
        @current_page? 0
      end
    end

    # Memory.pages(2)

    defw html_write(write: I32.UnsafePointer, write_size: I32), I32, original_size: I32 do
      original_size = write_size

      Control.block Write do
        Write.write!("<a ", mut!(write), mut!(write_size))

        # <a href="uri">Text</a>
      end

      write_size - original_size
    end
  end

  defmodule PrimaryNav do
    use Orb
    defstruct [:path]

    Memory.pages(2)

    defw html_body_content(), Str, write: I32.UnsafePointer, write_size: I32 do
      write = 0x10000
      write_size = 0x10000

      Write.write!(~S|<nav aria-label="Primary">|, mut!(write), mut!(write_size))

      {write, 0x10000 - write_size}

      # """
      # <nav aria-label="Primary">
      #   <a href="/">Home</a>
      #   <a href="/about">About</a>
      # </nav>
      # """
    end
  end

  describe "send_html/3" do
    test "form with method get", %{conn: conn} do
      conn =
        GoldenOrb.html(conn, %HTMLLayout{lang: :es}, [
          %ViewTransitions{},
          %PrimaryNav{},
          %SearchForm{}
        ])

      assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]

      assert conn.resp_body == """
             <!DOCTYPE html><html lang="es"><meta charset=utf-8>
             <title>Search</title>
             <style>
             @view-transition { navigation: auto }
             </style>
             <body>
             <nav aria-label="Primary">
             </nav>
             <form>
               <input name=\"q\" placeholder=\"Search\">
             </form>
             """
    end
  end
end
