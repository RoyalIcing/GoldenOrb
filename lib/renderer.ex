defmodule GoldenOrb.Renderer do
  @moduledoc """
  Renders an Orb module to a string using Wasmex.
  """

  defp compile_orb_struct(%module{}) do
    wat = Orb.to_wat(module)
    {:ok, wasmex_store} = Wasmex.Store.new()

    wasmex_module =
      Wasmex.Module.compile(wasmex_store, wat)
      |> case do
        {:ok, wasmex_module} ->
          wasmex_module

        {:error, reason} when is_binary(reason) ->
          IO.puts(wat)
          raise reason
      end

    %{wasmex_module: wasmex_module, wasmex_store: wasmex_store}
  end

  @doc """
  Returns `true` if the given Orb `struct` implements all of the functions in `func_names`.
  """
  def orb_struct_implements?(struct, func_names) do
    %{wasmex_module: wasmex_module} = compile_orb_struct(struct)

    exports = Wasmex.Module.exports(wasmex_module)

    Enum.all?(func_names, fn func_name ->
      func_name = to_string(func_name)

      Enum.any?(exports, fn
        {^func_name, {:fn, [], [:i32, :i32]}} -> true
        _ -> false
      end)
    end)
  end

  def render_orb_struct(struct, render_func_names) when is_list(render_func_names) do
    %{wasmex_module: wasmex_module, wasmex_store: wasmex_store} = compile_orb_struct(struct)

    struct_stringly =
      struct |> Map.from_struct() |> Map.new(fn {key, value} -> {Atom.to_string(key), value} end)

    {:ok, pid} = Wasmex.start_link(%{store: wasmex_store, module: wasmex_module})
    {:ok, memory} = Wasmex.memory(pid)
    {:ok, store} = Wasmex.store(pid)
    {:ok, instance} = Wasmex.instance(pid)

    call_function = &Wasmex.call_function(pid, &1, &2)
    read_binary = &Wasmex.Memory.read_binary(store, memory, &1, &2)

    for {global_name, {:global, %{type: _type, mutability: :var}}} <-
          Wasmex.Module.exports(wasmex_module) do
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
