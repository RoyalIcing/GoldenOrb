defprotocol GoldenOrb.RobotsTxt do
  def robots_txt(context)
end

defprotocol GoldenOrb.HTTPResponse do
  def status(context)
  def headers(context)
  def body(context)
end

defprotocol GoldenOrb.SVG do
  def image_svg_xml(context)
end

defprotocol GoldenOrb.GLSLVertexShader do
  def glsl_vertex(context)
end

defprotocol GoldenOrb.GLSLFragmentShader do
  def glsl_fragment(context)
end
