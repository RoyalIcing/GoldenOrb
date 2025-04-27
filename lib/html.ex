defprotocol GoldenOrb.HTML do
  @fallback_to_any true
  def text_html(context)
  # def lang(context)
  # def title(context)
  # def html_attributes(context)
  # def html_head(context)
  # def html_body(context)
end

defimpl GoldenOrb.HTML, for: Any do
  def text_html(struct) do
    %{html_attributes: html_attributes, html_head: html_head, html_body: html_body} =
      GoldenOrb.Renderer.render_orb_struct(struct, [:html_attributes, :html_head, :html_body])

    [
      "<!DOCTYPE html>",
      "<html ",
      html_attributes,
      ">",
      "<meta charset=utf-8>\n",
      # "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
      # "<title>#{struct.title}</title>",
      html_head,
      html_body
    ]
  end
end
