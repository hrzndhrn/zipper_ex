defmodule Support.Zipper do
  @moduledoc false

  use ZipperEx

  @impl ZipperEx
  def branch?(item) do
    case item do
      {_, [_ | _]} -> true
      _else -> false
    end
  end

  @impl ZipperEx
  def children({_, children}), do: children

  @impl ZipperEx
  def make_node({value, _children}, children), do: {value, children}

  def make_node(value, children), do: {value, children}
end
