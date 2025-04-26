defprotocol GoldenOrb.CSS do
  @fallback_to_any true
  def text_css(context)
end

defimpl GoldenOrb.CSS, for: Any do
  def text_css(%module{}) do
    # wat = Orb.to_wat(@for)
    wat = Orb.to_wat(module)
    {:ok, pid} = Wasmex.start_link(%{bytes: wat})
    {:ok, memory} = Wasmex.memory(pid)
    {:ok, store} = Wasmex.store(pid)

    call_function = &Wasmex.call_function(pid, &1, &2)
    read_binary = &Wasmex.Memory.read_binary(store, memory, &1, &2)

    {:ok, [ptr, size]} = call_function.(:text_css, [])
    text = read_binary.(ptr, size)
    text
  end
end
