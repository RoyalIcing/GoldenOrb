defprotocol GoldenOrb.CSS do
  @fallback_to_any true
  def text_css(context)
end

defimpl GoldenOrb.CSS, for: Any do
  def text_css(struct) do
    GoldenOrb.Renderer.render_orb_struct(struct, [:text_css])
    |> Map.fetch!(:text_css)
  end
end
