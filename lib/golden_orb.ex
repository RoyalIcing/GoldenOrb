defmodule GoldenOrb do
  @moduledoc """
  Documentation for `GoldenOrb`.
  """

  def html(conn, layout, fragments) do
    GoldenOrb.Plug.send_html(conn, layout, fragments)
  end
end
