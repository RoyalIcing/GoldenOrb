defprotocol GoldenOrb.CSS do
  @fallback_to_any true
  def text_css(context)
end

defimpl GoldenOrb.CSS, for: Any do
  def text_css(%module{} = struct) do
    # wat = Orb.to_wat(@for)
    wat = Orb.to_wat(module)
    {:ok, store} = Wasmex.Store.new()
    {:ok, wasm_module} = Wasmex.Module.compile(store, wat)

    # struct_keys = Map.keys(struct) |> Enum.map(&Atom.to_string/1)
    struct_stringly =
      struct |> Map.from_struct() |> Map.new(fn {key, value} -> {Atom.to_string(key), value} end)

    # for {global_name, {:global, %{type: type, mutability: :var}}} <-
    #       Wasmex.Module.exports(wasm_module) do
    #   IO.puts("Global: #{inspect(global_name)} (#{inspect(type)})")
    # end

    {:ok, pid} = Wasmex.start_link(%{store: store, module: wasm_module})
    {:ok, memory} = Wasmex.memory(pid)
    {:ok, store} = Wasmex.store(pid)
    {:ok, instance} = Wasmex.instance(pid)

    for {global_name, {:global, %{type: type, mutability: :var}}} <-
          Wasmex.Module.exports(wasm_module) do
      initial_value = Map.get(struct_stringly, global_name)
      IO.puts("Global: #{inspect(global_name)} (#{inspect(type)}) #{inspect(initial_value)})")

      case initial_value do
        false ->
          Wasmex.Instance.set_global_value(store, instance, global_name, 0)

        true ->
          Wasmex.Instance.set_global_value(store, instance, global_name, 1)

        integer when is_integer(integer) ->
          Wasmex.Instance.set_global_value(store, instance, global_name, integer)
      end
    end

    call_function = &Wasmex.call_function(pid, &1, &2)
    read_binary = &Wasmex.Memory.read_binary(store, memory, &1, &2)

    {:ok, [ptr, size]} = call_function.(:text_css, [])
    text = read_binary.(ptr, size)
    text
  end
end
