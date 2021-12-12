# ZipperEx
[![Hex.pm: version](https://img.shields.io/hexpm/v/zipper_ex.svg?style=flat-square)](https://hex.pm/packages/zipper_ex)
[![GitHub: CI status](https://img.shields.io/github/workflow/status/hrzndhrn/zipper_ex/CI?style=flat-square)](https://github.com/hrzndhrn/zipper_ex/actions)
[![Coveralls: coverage](https://img.shields.io/coveralls/github/hrzndhrn/zipper_ex?style=flat-square)](https://coveralls.io/github/hrzndhrn/zipper_ex)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://github.com/hrzndhrn/zipper_ex/blob/main/LICENSE.md)

An Elixir implementation for Zipper based on the paper
[Functional pearl: the zipper](
https://www.st.cs.uni-saarland.de/edu/seminare/2005/advanced-fp/docs/huet-zipper.pdf).
by Gérard Huet.

`ZipperEx` provides functions to handle and traverse tree data structures.

## Installation

The package can be installed by adding `zipper_ex` to your list of dependencies in
`mix.exs`:

```elixir
def deps do
  [
    {:zipper_ex, "~> 0.1"}
  ]
end
```

The [documentation](https://hexdocs.pm/zipper_ex) can be found on [hexdocs](https://hexdocs.pm/).

## Usage

To create a zipper you can use the `ZipperEx.Zipable` protocol or create a
module.

### Creating a zipper module

Imagine we have a tree structure based on a tuple with an integer value and a
list of cildren. The leafs of the tree are also integers. A tree may then look
like the following:

```elixir
{1, [2, {3, [4, 5]}, 6, {7, [0]}]}
#   1
# +-+-+---+-+
# 2   3   6 7
#   +-+-+   +
#   4   5   0
```

To handle this tree we create the following module:
```elixir
defmodule My.Zipper do
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
```

For `use ZipperEx` we have to implement the callbacks `c:branch?/1`,
`c:children/1` and `c:make_node/2`.

The `My.Zipper` module contains all functions the `ZipperEx` also
provides.

We can now use `My.Zipper`.

```elixir
iex> alias My.Zipper
iex> zipper = Zipper.new({1, [2, {3, [4, 5]}, 6, {7, [0]}]})
#ZipperEx<{1, [2, {3, [4, 5]}, 6, {7, [0]}]}>
iex> zipper = Zipper.down(zipper)
#ZipperEx<2>
iex> zipper = Zipper.right(zipper)
#ZipperEx<{3, [4, 5]}>
iex> zipper |> Zipper.remove() |> Zipper.root()
{1, [2, 6, {7, [0]}]}
```

### Using the `ZipperEx.Zipable` protocol

Similar to the module example the protocol needs implementations for
`ZipperEx.Zipable.branch?/1`, `ZipperEx.Zipable.children/1` and
`ZipperEx.Zipable.make_node/2`.

```elixir
defmodule My.TreeNode do
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
```

`My.TreeNode` can then be used as follows:

```elixir
iex> alias My.TreeNode
iex> tree = TreeNode.new({1, [2, {3, [4, 5]}]})
iex> zipper = ZipperEx.new(tree)
iex> ZipperEx.down(zipper)
#ZipperEx<#TreeNode<2, []>>
iex> zipper |> ZipperEx.down() |> ZipperEx.rightmost()
#ZipperEx<#TreeNode<3, [#TreeNode<4, []>, #TreeNode<5, []>]>>
iex> {_zipper, acc} = ZipperEx.traverse(zipper, [], fn z, acc ->
...>   node = ZipperEx.node(z)
...>   {z, [node.value | acc]}
...> end)
iex> acc
[5, 4, 3, 2, 1]
```

