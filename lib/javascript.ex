defprotocol GoldenOrb.JavaScript do
  @fallback_to_any true
  def text_javascript(context)
end

defimpl GoldenOrb.JavaScript, for: Any do
  def text_javascript(struct) do
    GoldenOrb.Renderer.render_orb_struct(struct, [:text_javascript])
    |> Map.fetch!(:text_javascript)
  end
end
