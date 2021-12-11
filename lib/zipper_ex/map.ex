defmodule ZipperEx.Map do
  @moduledoc """
  A zipper implementation for nested maps.

  ## Examples

      iex> zipper = ZipperEx.Map.new(%{a: 1, b: %{c: 2, d: 3}})
      iex> {_, acc} = ZipperEx.traverse(zipper, [], fn z, acc ->
      ...>   {z, [ZipperEx.node(z) | acc]}
      ...> end)
      ...> Enum.reverse(acc)
      [
        %{a: 1, b: %{c: 2, d: 3}},
        {:a, 1},
        {:b, %{c: 2, d: 3}},
        {:c, 2},
        {:d, 3}
      ]
  """

  use ZipperEx

  @impl ZipperEx
  def branch?(node) when is_map(node), do: true
  def branch?({_key, children}) when is_map(children), do: true
  def branch?(_item), do: false

  @impl ZipperEx
  def children({_key, children}), do: Enum.to_list(children)
  def children(node), do: Enum.to_list(node)

  @impl ZipperEx
  def make_node({key, _children}, children), do: {key, Enum.into(children, %{})}

  def make_node(_node, children), do: Enum.into(children, %{})
end
