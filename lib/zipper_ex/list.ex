defmodule ZipperEx.List do
  @moduledoc """
  A zipper implementation for nested lists.

  ## Examples

      iex> zipper = ZipperEx.List.new([1, [2, [3, 4], 5], 6])
      iex> {_, acc} = ZipperEx.traverse(zipper, [], fn z, acc ->
      ...>   {z, [ZipperEx.node(z) | acc]}
      ...> end)
      ...> Enum.reverse(acc)
      [
        [1, [2, [3, 4], 5], 6],
        1,
        [2, [3, 4], 5],
        2,
        [3, 4],
        3,
        4,
        5,
        6
      ]
  """

  use ZipperEx

  @impl ZipperEx
  def branch?(node) when is_list(node), do: not Keyword.keyword?(node)
  def branch?(_item), do: false

  @impl ZipperEx
  def children(children), do: children

  @impl ZipperEx
  def make_node(_list, children), do: children
end
