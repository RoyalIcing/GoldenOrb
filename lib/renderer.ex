defmodule GoldenOrb.Renderer do
  def render_orb_struct(%module{} = struct, render_func_names) when is_list(render_func_names) do
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

    for render_func_name <- render_func_names, into: %{} do
      {:ok, [ptr, size]} = call_function.(render_func_name, [])
      text = read_binary.(ptr, size)
      {render_func_name, text}
    end
  end
end
