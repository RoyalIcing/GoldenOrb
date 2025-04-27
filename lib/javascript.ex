defprotocol GoldenOrb.JavaScript do
  @fallback_to_any true
  def text_javascript(context)
end

defimpl GoldenOrb.JavaScript, for: Any do
  def text_javascript(%module{} = struct) do
    wat = Orb.to_wat(module)
    {:ok, store} = Wasmex.Store.new()
    {:ok, wasm_module} = Wasmex.Module.compile(store, wat)

    struct_stringly =
      struct |> Map.from_struct() |> Map.new(fn {key, value} -> {Atom.to_string(key), value} end)

    {:ok, pid} = Wasmex.start_link(%{store: store, module: wasm_module})
    {:ok, memory} = Wasmex.memory(pid)
    {:ok, store} = Wasmex.store(pid)
    {:ok, instance} = Wasmex.instance(pid)

    call_function = &Wasmex.call_function(pid, &1, &2)
    read_binary = &Wasmex.Memory.read_binary(store, memory, &1, &2)

    for {global_name, {:global, %{type: _type, mutability: :var}}} <-
          Wasmex.Module.exports(wasm_module) do
      initial_value = Map.get(struct_stringly, global_name)

      case initial_value do
        false ->
          Wasmex.Instance.set_global_value(store, instance, global_name, 0)

        true ->
          Wasmex.Instance.set_global_value(store, instance, global_name, 1)

        integer when is_integer(integer) ->
          Wasmex.Instance.set_global_value(store, instance, global_name, integer)

        atom when is_atom(atom) ->
          {:ok, [value]} = call_function.("#{global_name}_#{atom}", [])
          Wasmex.Instance.set_global_value(store, instance, global_name, value)
      end
    end

    {:ok, [ptr, size]} = call_function.(:text_javascript, [])
    text = read_binary.(ptr, size)
    text
  end
end
