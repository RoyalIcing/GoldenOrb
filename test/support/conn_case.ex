defmodule GoldenOrb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
    end
  end

  setup _context do
    conn = Plug.Adapters.Test.Conn.conn(%Plug.Conn{}, :get, "/", nil)

    {:ok, conn: conn}
  end
end
