defmodule GoldenOrb do
  @moduledoc """
  Documentation for `GoldenOrb`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> GoldenOrb.hello()
      :coming_soon

  """
  def hello do
    :coming_soon
  end

  def html(conn, layout, fragments) do
    GoldenOrb.Plug.send_html(conn, layout, fragments)
  end
end
