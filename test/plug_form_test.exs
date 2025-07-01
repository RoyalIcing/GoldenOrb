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

    def write!(string, write!, write_size!) when is_binary(string) or is_struct(string) do
      read_size =
        case string do
          string when is_binary(string) ->
            byte_size(string)

          %Orb.VariableReference{} = var_ref ->
            var_ref[:size]
        end

      read_ptr =
        case string do
          string when is_binary(string) ->
            Orb.DSL.const(string).memory_offset

          %Orb.VariableReference{} = var_ref ->
            var_ref[:ptr]
        end

      Orb.snippet do
        # use Orb.DSL
        # use Orb.Numeric.DSL

        if write_size!.read < read_size do
          unreachable!()
        end

        # assert!(write_size!.read >= read_size)
        Memory.copy!(write!.read, read_ptr, read_size)
        Orb.MutRef.store(write!, write!.read + read_size)
        Orb.MutRef.store(write_size!, write_size!.read - read_size)
      end
    end
  end

  defprotocol Writer do
    @spec write!(t, any, any) :: any
    def write!(value, write!, write_size!)
  end

  defimpl Writer, for: BitString do
    def write!(value, write!, write_size!) do
      Write.write!(value, write!, write_size!)
    end
  end

  defimpl Writer, for: Integer do
    def write!(value, write!, write_size!) do
      require Orb

      Orb.snippet do
        if write_size!.read < 1 do
          unreachable!()
        end

        Orb.Memory.store!(Orb.I32.U8, write!.read, value)
        Orb.MutRef.store(write!, write!.read + 1)
        Orb.MutRef.store(write_size!, write_size!.read - 1)
      end
    end
  end

  defimpl Writer, for: List do
    def write!(values, write!, write_size!) do
      Orb.InstructionSequence.new(
        nil,
        for value <- values do
          Writer.write!(value, write!, write_size!)
        end
      )
    end
  end

  defimpl Writer, for: Orb.VariableReference do
    def write!(var_ref, write!, write_size!) when var_ref.push_type == Orb.Str do
      require Orb

      Orb.snippet do
        if write_size!.read < var_ref[:size] do
          unreachable!()
        end

        Orb.Memory.copy!(write!.read, var_ref[:ptr], var_ref[:size])
        Orb.MutRef.store(write!, write!.read + var_ref[:size])
        Orb.MutRef.store(write_size!, write_size!.read - var_ref[:size])
      end
    end
  end

  defimpl Writer, for: Orb.IfElse do
    def write!(if_else, write!, write_size!) do
      if_else =
        update_in(if_else.when_true.body, fn body ->
          [Writer.write!(body, write!, write_size!)]
        end)

      if_else =
        if if_else.when_false do
          update_in(if_else.when_false.body, fn body ->
            [Writer.write!(body, write!, write_size!)]
          end)
        else
          if_else
        end

      Map.put(if_else, :push_type, nil)
    end
  end

  defimpl Writer, for: Orb.Block do
    def write!(block, write!, write_size!) do
      update_in(block.body, fn instructions ->
        Orb.InstructionSequence.new(nil, [Writer.write!(instructions.body, write!, write_size!)])
      end)
      |> Map.put(:push_type, nil)
    end
  end

  defmodule NavLink do
    use Orb
    defstruct href: "", text: "", current_page?: false

    def fields do
      [
        href: Str,
        text: Str,
        current_page?: I32
      ]
    end

    with @behaviour Orb.CustomType do
      @impl Orb.CustomType
      def wasm_type() do
        fields()
        |> Keyword.values()
        |> List.to_tuple()
      end
    end

    Orb.set_func_prefix("NavLink")

    defw html_write(
           href: Str,
           text: Str,
           current_page?: I32,
           write: I32.UnsafePointer,
           write_size: I32
         ) ::
           {I32.UnsafePointer, I32} do
      Orb.Control.block :items do
        "<a "
        "href=\""
        href
        "\""

        if current_page? do
          " aria-current=page"
        end

        ">"
        text
        "</a>"
      end
      |> Writer.write!(mut!(write), mut!(write_size))

      # Writer.write!(
      #   [
      #     "<a ",
      #     "href=\"",
      #     href,
      #     "\"",
      #     if current_page? do
      #       " aria-current=page"
      #     end,
      #     ">",
      #     text,
      #     "</a>"
      #   ],
      #   mut!(write),
      #   mut!(write_size)
      # )

      {write, write_size}
    end

    alias __MODULE__

    defimpl Writer do
      def write!(nav_link, write!, write_size!) do
        # %Orb.VariableReference{entries: [write!, write_size!]}
        # |> Orb.VariableReference.set(NavLink.html_write(value, write!.read, write_size!.read))

        Orb.InstructionSequence.new(nil, [
          NavLink.html_write(
            nav_link.href,
            nav_link.text,
            case nav_link.current_page? do
              false -> 0
              true -> 1
              other -> other
            end,
            write!.read,
            write_size!.read
          ),
          write_size!.write,
          write!.write
        ])

        # Orb.snippet Orb.Numeric, write!: I32.UnsafePointer, write_size!: I32 do
        #   {write!, write_size!} = NavLink.html_write(value, dbg(write!).read, write_size!.read)
        #   # {write!, write_size!} = NavLink.html_write(value, write!, write_size!)
        # end
      end
    end
  end

  defmodule Form do
    use Orb
    defstruct id: :required, method: "get", children: []

    def get(opts), do: struct!(__MODULE__, opts)

    Orb.set_func_prefix("Form")

    defw html_write_start(
           id: Str,
           method: Str,
           write: I32.UnsafePointer,
           write_size: I32
         ) :: {I32.UnsafePointer, I32} do
      Orb.Control.block :items do
        ~S|<form id="|
        id
        ~S|" method="|
        method
        ~s|">\n|
      end
      |> Writer.write!(mut!(write), mut!(write_size))

      {write, write_size}
    end

    alias __MODULE__

    defimpl Writer do
      def write!(form, write!, write_size!) do
        Orb.InstructionSequence.new(nil, [
          Orb.InstructionSequence.new(nil, [
            # TODO: Make %Orb.Instruction.Call implement Writer
            @for.html_write_start(
              form.id,
              form.method,
              write!.read,
              write_size!.read
            ),
            write_size!.write,
            write!.write
          ]),
          Writer.write!(form.children, write!, write_size!),
          Writer.write!(~s|</form>\n|, write!, write_size!)
        ])
      end
    end
  end

  defmodule Textbox do
    use Orb
    defstruct id: "", name: "", value: "", label: ""

    Orb.set_func_prefix("Textbox")

    defw html_write(
           id: Str,
           name: Str,
           value: Str,
           label: Str,
           write: I32.UnsafePointer,
           write_size: I32
         ) :: {I32.UnsafePointer, I32} do
      Orb.Control.block :items do
        ~S|<label for="|
        id
        ~S|">|
        label
        ~S|<input id="|
        id
        ~S|" name="|
        name
        ~S|" value="|
        value
        ~S|"></label>|
        ?\n
      end
      |> Writer.write!(mut!(write), mut!(write_size))

      {write, write_size}
    end

    alias __MODULE__

    defimpl Writer do
      def write!(textbox, write!, write_size!) do
        Orb.InstructionSequence.new(nil, [
          @for.html_write(
            textbox.id,
            textbox.name,
            textbox.value,
            textbox.label,
            write!.read,
            write_size!.read
          ),
          write_size!.write,
          write!.write
        ])
      end
    end
  end

  defmodule PrimaryNav do
    use Orb
    defstruct [:path]

    Memory.pages(2)

    Orb.include(NavLink)
    Orb.include(Form)
    Orb.include(Textbox)

    import Writer

    defw html_body_content() :: Str do
      local(write: I32.UnsafePointer, write_size: I32)
      write = 0x10000
      write_size = 0x10000

      write!(
        [
          ~S|<nav aria-label="Primary">|,
          ?\n,
          %NavLink{href: "/", text: "Home", current_page?: true},
          ?\n,
          %NavLink{href: "/about", text: "About"},
          ?\n,
          ~S|</nav>|,
          ?\n
        ],
        mut!(write),
        mut!(write_size)
      )

      {0x10000, 0x10000 - write_size}

      # """
      # <nav aria-label="Primary">
      #   <a href="/">Home</a>
      #   <a href="/about">About</a>
      # </nav>
      # """
    end
  end

  defmodule ProfileForm do
    use Orb
    defstruct [:path]

    Memory.pages(2)

    Orb.include(Form)
    Orb.include(Textbox)

    import Writer

    defp body() do
      Form.get(
        id: "profile",
        children: [
          %Textbox{id: "bio", name: "bio", value: "", label: "Bio"}
        ]
      )
    end

    defw html_body_content() :: Str do
      local(write: I32.UnsafePointer, write_size: I32)
      write = 0x10000
      write_size = 0x10000

      write!(
        body(),
        mut!(write),
        mut!(write_size)
      )

      {0x10000, 0x10000 - write_size}
    end
  end

  describe "send_html/3" do
    test "form with method get", %{conn: conn} do
      conn =
        GoldenOrb.html(conn, %HTMLLayout{lang: :es}, [
          %ViewTransitions{},
          %PrimaryNav{},
          %ProfileForm{},
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
             <a href="/" aria-current=page>Home</a>
             <a href="/about">About</a>
             </nav>
             <form id="profile" method="get">
             <label for="bio">Bio<input id="bio" name="bio" value=""></label>
             </form>
             <form>
               <input name=\"q\" placeholder=\"Search\">
             </form>
             """
    end
  end
end
