defprotocol GoldenOrb.HTML do
  @fallback_to_any true
  def text_html(document)

  @fallback_to_any true
  def text_html(document, fragments)

  @fallback_to_any true
  def text_html_fragment(context)
  # def lang(context)
  # def title(context)
  # def html_attributes(context)
  # def html_head(context)
  # def html_body(context)
end

defimpl GoldenOrb.HTML, for: Any do
  def text_html(document, fragments) do
    %{html_attributes: html_attributes, html_head: html_head, html_body: html_body} =
      GoldenOrb.Renderer.render_orb_struct(document, [:html_attributes, :html_head, :html_body])

    {fragment_heads, fragment_bodies} =
      for fragment <- fragments, reduce: {[], []} do
        {fragment_heads, fragment_bodies} ->
          %{html_head_content: html_head_content, html_body_content: html_body_content} =
            text_html_fragment(fragment)

          {
            [html_head_content | fragment_heads],
            [html_body_content | fragment_bodies]
          }
      end

    [
      "<!DOCTYPE html>",
      "<html ",
      html_attributes,
      ">",
      "<meta charset=utf-8>\n",
      # "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
      # "<title>#{struct.title}</title>",
      html_head,
      Enum.reverse(fragment_heads),
      html_body,
      Enum.reverse(fragment_bodies)
    ]
  end

  def text_html(document) do
    text_html(document, [])
  end

  @doc """
  Returns a map with `:html_head_content` and `:html_body_content` string values.

  Raises if the Orb module does not implement the `html_head_content` and `html_body_content` functions.
  """
  def text_html_fragment(struct) do
    cond do
      GoldenOrb.Renderer.orb_struct_implements?(struct, [:html_head_content, :html_body_content]) ->
        GoldenOrb.Renderer.render_orb_struct(struct, [:html_head_content, :html_body_content])

      GoldenOrb.Renderer.orb_struct_implements?(struct, [:html_head_content]) ->
        GoldenOrb.Renderer.render_orb_struct(struct, [:html_head_content])
        |> Map.put(:html_body_content, [])

      GoldenOrb.Renderer.orb_struct_implements?(struct, [:html_body_content]) ->
        GoldenOrb.Renderer.render_orb_struct(struct, [:html_body_content])
        |> Map.put(:html_head_content, [])

      GoldenOrb.Renderer.orb_struct_implements?(struct, [:text_javascript]) ->
        javascript_source = GoldenOrb.JavaScript.text_javascript(struct)

        %{
          html_head_content: [
            ~s|<script type="module">\n|,
            Plug.HTML.html_escape_to_iodata(javascript_source),
            "</script>\n"
          ],
          html_body_content: []
        }

      GoldenOrb.Renderer.orb_struct_implements?(struct, [:text_css]) ->
        css_source = GoldenOrb.CSS.text_css(struct)

        %{
          html_head_content: [
            "<style>\n",
            Plug.HTML.html_escape_to_iodata(css_source),
            "</style>\n"
          ],
          html_body_content: []
        }

      true ->
        raise "Your Orb module #{inspect(struct)} does not implement any HTML-compatible functions"
    end
  end
end
