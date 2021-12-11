defmodule Support.TreeNode do
  @moduledoc false

  defstruct value: nil, children: []

  def new({value, children}) do
    struct!(__MODULE__, value: value, children: Enum.map(children, &new/1))
  end

  def new(value), do: struct!(__MODULE__, value: value)

  defimpl ZipperEx.Zipable do
    def branch?(%{children: [_ | _]}), do: true

    def branch?(_node), do: false

    def children(%{children: children}), do: children

    def make_node(node, children), do: %{node | children: children}
  end

  defimpl Inspect do
    def inspect(node, _opts), do: "#TreeNode<#{node.value}, #{inspect(node.children)}>"
  end
end
