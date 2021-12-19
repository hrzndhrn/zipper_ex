defmodule ZipperEx do
  @moduledoc ~S"""
  An Elixir implementation for Zipper based on the paper
  [Functional pearl: the zipper](
  https://www.st.cs.uni-saarland.de/edu/seminare/2005/advanced-fp/docs/huet-zipper.pdf).
  by Gérard Huet.

  `ZipperEx` provides functions to handle an traverse tree data structures.

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
  defmodule Support.Zipper do
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

  The `Support.Zipper` module contains all functions the `ZipperEx` also
  provides.

  We can now use `Support.Zipper`.

      iex> alias Support.Zipper
      iex> zipper = Zipper.new({1, [2, {3, [4, 5]}, 6, {7, [0]}]})
      #ZipperEx<{1, [2, {3, [4, 5]}, 6, {7, [0]}]}>
      iex> zipper = Zipper.down(zipper)
      #ZipperEx<2>
      iex> zipper = Zipper.right(zipper)
      #ZipperEx<{3, [4, 5]}>
      iex> Zipper.remove(zipper) |> Zipper.root()
      {1, [2, 6, {7, [0]}]}
      iex> {_zipper, acc} = zipper |> ZipperEx.top() |> ZipperEx.traverse([], fn
      ...>   %{loc: {_value, _children}} = zipper, acc -> {zipper, acc}
      ...>   %{loc: value} = zipper, acc -> {zipper, [value | acc]}
      ...> end)
      iex> acc
      [0, 6, 5, 4, 2]

  ### Using the `ZipperEx.Zipable` protocol

  Similar to the module example the protocol needs implementations for
  `ZipperEx.Zipable.branch?/1`, `ZipperEx.Zipable.children/1` and
  `ZipperEx.Zipable.make_node/2`.

  ```elixir
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
  ```

  `Support.TreeNode` can then be used as follows:

        iex> alias Support.TreeNode
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

  ## Example supporters

  The module `Support.Zipper` and `Support.TreeNode` are also used in the
  examples for this module.
  """

  import Kernel, except: [node: 1]

  alias ZipperEx.Zipable

  @type tree :: term()

  @typedoc """
  The `ZipperEx` type:
  * `loc`: The current location of the zipper.
  * `left`: The left side.
  * `left`: The right side.
  * `path`: The path to the top.
  * `module`: The zipper module.
  """
  @type t(tree) :: %ZipperEx{
          loc: tree,
          left: [tree],
          path: t(tree) | nil | :end,
          right: [tree],
          module: module() | nil
        }
  @type t :: t(term())

  @enforce_keys [:loc]
  defstruct left: [],
            path: nil,
            right: [],
            loc: nil,
            module: nil

  @doc """
  Should return `true` if the given `node` is a branch.
  """
  @callback branch?(node :: term()) :: boolean

  @doc """
  Returns the children of the given `node`.
  """
  @callback children(node :: term()) :: [term()]

  @doc """
  Creates a `node` from the given `node` and `children`.
  """
  @callback make_node(node :: term(), children :: [term()]) :: term()

  defmacro __using__(_opts) do
    quote do
      @behaviour ZipperEx

      def new(tree), do: struct!(ZipperEx, loc: tree, module: __MODULE__)

      def branch?(%ZipperEx{loc: loc}), do: branch?(loc)
      def children(%ZipperEx{loc: loc}), do: children(loc)
      def make_node(%ZipperEx{loc: loc}, children), do: make_node(loc, children)

      defdelegate append_child(zipper, child), to: ZipperEx
      defdelegate down(zipper), to: ZipperEx
      defdelegate end?(zipper), to: ZipperEx
      defdelegate find(zipper, fun), to: ZipperEx
      defdelegate insert_child(zipper, child), to: ZipperEx
      defdelegate insert_right(zipper, child), to: ZipperEx
      defdelegate insert_left(zipper, child), to: ZipperEx
      defdelegate left(zipper), to: ZipperEx
      defdelegate leftmost(zipper), to: ZipperEx
      defdelegate map(zipper, fun), to: ZipperEx
      defdelegate next(zipper), to: ZipperEx
      defdelegate node(zipper), to: ZipperEx
      defdelegate prev(zipper), to: ZipperEx
      defdelegate remove(zipper), to: ZipperEx
      defdelegate root(zipper), to: ZipperEx
      defdelegate replace(zipper, node), to: ZipperEx
      defdelegate right(zipper), to: ZipperEx
      defdelegate rightmost(zipper), to: ZipperEx
      defdelegate top(zipper), to: ZipperEx
      defdelegate traverse(zipper, fun), to: ZipperEx
      defdelegate traverse(zipper, acc, fun), to: ZipperEx
      defdelegate traverse_while(zipper, fun), to: ZipperEx
      defdelegate traverse_while(zipper, acc, fun), to: ZipperEx
      defdelegate up(zipper), to: ZipperEx
      defdelegate update(zipper, fun), to: ZipperEx
    end
  end

  @doc """
  Returns a new `%ZipperEx{}` from a given `tree` or `%ZipperEx`.

  ## Examples

      iex> alias Support.Zipper
      iex> zipper = Support.Zipper.new({1, [{2, [3, 4]}, 5]})
      #ZipperEx<{1, [{2, [3, 4]}, 5]}>
      iex> zipper |> ZipperEx.next() |> ZipperEx.new()
      #ZipperEx<{2, [3, 4]}>
      iex> zipper |> Zipper.next() |> ZipperEx.new()
      #ZipperEx<{2, [3, 4]}>

      iex> alias Support.TreeNode
      iex> zipper = ZipperEx.new(TreeNode.new({1, [2]}))
      #ZipperEx<#TreeNode<1, [#TreeNode<2, []>]>>
      iex> zipper |> ZipperEx.next() |> ZipperEx.new()
      #ZipperEx<#TreeNode<2, []>>
  """
  @spec new(ZipperEx.t() | tree()) :: ZipperEx.t()
  def new(%ZipperEx{path: nil} = zipper), do: zipper

  def new(%ZipperEx{} = zipper), do: %ZipperEx{zipper | path: nil, left: [], right: []}

  def new(tree), do: struct!(ZipperEx, loc: tree)

  @doc """
  Returns `true` if the given `node` is a branch.
  """
  @spec branch?(ZipperEx.t()) :: boolean()
  def branch?(%ZipperEx{loc: loc, module: nil}), do: Zipable.branch?(loc)

  def branch?(%ZipperEx{} = zipper), do: Zipable.branch?(zipper)

  @doc """
  Returns the children of the given `node`.
  """
  @spec children(ZipperEx.t()) :: [tree()]
  def children(%ZipperEx{loc: loc, module: nil}), do: Zipable.children(loc)

  def children(%ZipperEx{} = zipper), do: Zipable.children(zipper)

  @doc """
  Creates a `node` from the given `node` and `children`.
  """
  @spec make_node(ZipperEx.t(), [tree()]) :: ZipperEx.t()
  def make_node(%ZipperEx{loc: loc, module: nil}, children) do
    Zipable.make_node(loc, children)
  end

  def make_node(%ZipperEx{} = zipper, children) do
    Zipable.make_node(zipper, children)
  end

  @doc """
  Appends a `child` to the given `zipper`.

  ## Examples

      iex> alias Support.Zipper
      iex> zipper = Zipper.new(1)
      #ZipperEx<1>
      iex> zipper = Zipper.append_child(zipper, 2)
      #ZipperEx<{1, [2]}>
      iex> Zipper.append_child(zipper, 3)
      #ZipperEx<{1, [2, 3]}>

      iex> alias Support.TreeNode
      iex> zipper = ZipperEx.new(TreeNode.new({1, [2]}))
      iex> ZipperEx.append_child(zipper, TreeNode.new(3))
      #ZipperEx<#TreeNode<1, [#TreeNode<2, []>, #TreeNode<3, []>]>>
  """
  @spec append_child(ZipperEx.t(), tree()) :: ZipperEx.t()
  def append_child(%ZipperEx{loc: loc, module: nil} = zipper, child) do
    case branch?(zipper) do
      true -> do_append_child(zipper, child)
      false -> %ZipperEx{zipper | loc: Zipable.make_node(loc, [child])}
    end
  end

  def append_child(%ZipperEx{} = zipper, child) do
    case branch?(zipper) do
      true -> do_append_child(zipper, child)
      false -> %ZipperEx{zipper | loc: Zipable.make_node(zipper, [child])}
    end
  end

  defp do_append_child(%ZipperEx{} = zipper, child) do
    down = down(zipper)
    up(%ZipperEx{down | right: down.right ++ [child]})
  end

  @doc """
  Returns the leftmost child node of the given `zipper`.

  Returns `nil` if the `zipper` is not a branch.

  ## Examples

      iex> alias Support.TreeNode
      iex> zipper = ZipperEx.new(TreeNode.new({1, [2, 3]}))
      iex> zipper = ZipperEx.down(zipper)
      #ZipperEx<#TreeNode<2, []>>
      iex> ZipperEx.down(zipper)
      nil
  """
  @spec down(ZipperEx.t()) :: ZipperEx.t()
  def down(%ZipperEx{} = zipper) do
    case branch?(zipper) do
      true ->
        [loc | right] = children(zipper)
        %ZipperEx{loc: loc, path: zipper, right: right, module: zipper.module}

      false ->
        nil
    end
  end

  @doc """
  Returns `true` when the zipper has reached the end.

  A zipper reached his end by using `traverse/2`, `traverse/3` or calling
  `next/1` until the end.

  ## Examples

      iex> zipper = Support.Zipper.new({1, [2]})
      iex> ZipperEx.end?(zipper)
      false
      iex> zipper |> ZipperEx.traverse(&Function.identity/1) |> ZipperEx.end?()
      true
      iex> zipper |> ZipperEx.next() |> ZipperEx.next() |> ZipperEx.end?()
      true
  """
  @spec end?(ZipperEx.t()) :: boolean()
  def end?(%ZipperEx{path: path}), do: path == :end

  @doc """
  Returns the first zipper for which `fun` returns a truthy value. If no such
  zipper is found, returns nil.

  Runs through the tree in a depth-first pre-order.

  ## Examples

      iex> alias Support.TreeNode
      iex> zipper = ZipperEx.new(TreeNode.new({1, [2, 3]}))
      iex> ZipperEx.find(zipper, fn node -> ZipperEx.branch?(node) == false end)
      #ZipperEx<#TreeNode<2, []>>
  """
  @spec find(ZipperEx.t() | nil, function()) :: ZipperEx.t() | nil
  def find(nil, _fun), do: nil

  def find(%ZipperEx{} = zipper, fun) when is_function(fun, 1) do
    if fun.(zipper), do: zipper, else: zipper |> next() |> find(fun)
  end

  @doc """
  Inserts a `child` to the given `zipper` at leftmost position.

  ## Examples

      iex> alias Support.TreeNode
      iex> zipper = ZipperEx.new(TreeNode.new({1, [3]}))
      iex> ZipperEx.insert_child(zipper, TreeNode.new(2))
      #ZipperEx<#TreeNode<1, [#TreeNode<2, []>, #TreeNode<3, []>]>>
  """
  @spec insert_child(ZipperEx.t(), tree()) :: ZipperEx.t()
  def insert_child(%ZipperEx{loc: loc, module: nil} = zipper, child) do
    case branch?(zipper) do
      true -> do_insert_child(zipper, child)
      false -> %ZipperEx{zipper | loc: Zipable.make_node(loc, [child])}
    end
  end

  def insert_child(%ZipperEx{} = zipper, child) do
    case branch?(zipper) do
      true -> do_insert_child(zipper, child)
      false -> %ZipperEx{zipper | loc: Zipable.make_node(zipper, [child])}
    end
  end

  defp do_insert_child(%ZipperEx{} = zipper, child) do
    up(%ZipperEx{down(zipper) | left: [child]})
  end

  @doc """
  Inserts a `child` as a left sibling to the given zipper.

  Raises an `ArgumentError` when called with an top level zipper.

  ## Examples

      iex> alias Support.TreeNode
      iex> zipper =
      ...>   TreeNode.new({1, [3]})
      ...>   |> ZipperEx.new()
      ...>   |> ZipperEx.down()
      iex> zipper |> ZipperEx.insert_left(TreeNode.new(2)) |> ZipperEx.top()
      #ZipperEx<#TreeNode<1, [#TreeNode<2, []>, #TreeNode<3, []>]>>
  """
  @spec insert_left(ZipperEx.t(), tree()) :: ZipperEx.t()
  def insert_left(%ZipperEx{path: nil}, _child) do
    raise(ArgumentError, message: "can't insert left sibling at the top level")
  end

  def insert_left(%ZipperEx{left: left} = zipper, child) do
    %ZipperEx{zipper | left: [child | left]}
  end

  @doc """
  Inserts a `child` as a right sibling to the given zipper.

  Raises an `ArgumentError` when called with an top level zipper.

  ## Examples

      iex> alias Support.TreeNode
      iex> zipper =
      ...>   TreeNode.new({1, [2]})
      ...>   |> ZipperEx.new()
      ...>   |> ZipperEx.down()
      iex> zipper |> ZipperEx.insert_right(TreeNode.new(3)) |> ZipperEx.top()
      #ZipperEx<#TreeNode<1, [#TreeNode<2, []>, #TreeNode<3, []>]>>
  """
  @spec insert_right(ZipperEx.t(), tree()) :: ZipperEx.t()
  def insert_right(%ZipperEx{path: nil}, _child) do
    raise(ArgumentError, message: "can't insert right sibling at the top level")
  end

  def insert_right(%ZipperEx{right: right} = zipper, child) do
    %ZipperEx{zipper | right: [child | right]}
  end

  @doc """
  Returns the left sibling of the given `zipper`.

  Returns `nil` if the `zipper` doesn't have a left sibling.

  ## Examples

      iex> alias Support.TreeNode
      iex> zipper =
      ...>   TreeNode.new({1, [10, 11]})
      ...>   |> ZipperEx.new()
      ...>   |> ZipperEx.down()
      iex> zipper = ZipperEx.right(zipper)
      #ZipperEx<#TreeNode<11, []>>
      iex> ZipperEx.right(zipper)
      nil
      iex> zipper = ZipperEx.left(zipper)
      #ZipperEx<#TreeNode<10, []>>
      iex> ZipperEx.left(zipper)
      nil
  """
  @spec left(ZipperEx.t()) :: ZipperEx.t() | nil
  def left(%ZipperEx{left: []}), do: nil

  def left(%ZipperEx{left: [next | left], loc: loc, right: right} = zipper) do
    %ZipperEx{zipper | loc: next, left: left, right: [loc | right]}
  end

  @doc """
  Returns the leftmost sibling of the given `zipper`.

  Returns the `zipper` himself if the given `zipper` is the leftmost sibling.

  ## Examples

      iex> alias Support.TreeNode
      iex> zipper =
      ...>   TreeNode.new({1, [10, 11, 12]})
      ...>   |> ZipperEx.new()
      ...>   |> ZipperEx.down()
      iex> zipper = ZipperEx.rightmost(zipper)
      #ZipperEx<#TreeNode<12, []>>
      iex> ZipperEx.leftmost(zipper)
      #ZipperEx<#TreeNode<10, []>>
  """
  @spec leftmost(ZipperEx.t()) :: ZipperEx.t()
  def leftmost(%ZipperEx{left: []} = zipper), do: zipper

  def leftmost(%ZipperEx{loc: loc, right: right, left: left} = zipper) do
    {left, [leftmost]} = Enum.split(left, -1)
    right = Enum.reverse(left) ++ [loc] ++ right
    %ZipperEx{zipper | loc: leftmost, left: [], right: right}
  end

  @doc """
  Returns a zipper where each node is the result of invoking `fun` on each
  corresponding node of the zipper.

  Runs through the tree in depth-first per-order.

  ## Examples

      iex> alias Support.Zipper
      iex> zipper = Zipper.new({1, [2, {3, [400, 500]}, 6]})
      iex> Zipper.map(zipper, fn
      ...>   {value, children} -> {value * 2, children}
      ...>   value -> value * 2
      ...> end)
      #ZipperEx<{2, [4, {6, [800, 1000]}, 12]}>
  """
  @spec map(ZipperEx.t(), (tree() -> tree())) :: ZipperEx.t()
  def map(%ZipperEx{} = zipper, fun) do
    traverse(zipper, fn node -> update(node, fun) end)
  end

  @doc """
  Returns the next zipper for the given `zipper`.

  The function walks through the tree in a depth-first pre-order. After the last
  Returns to the root after the last zipper and marks the zipper as ended. An
  ended zipper is detectable via `end?/1`. Calling `next/1` for
  an ended `zipper` returns the given `zipper`.

  ## Examples

      iex> zipper = Support.Zipper.new({1, [{2, [3, 4]}, 5]})
      #ZipperEx<{1, [{2, [3, 4]}, 5]}>
      iex> zipper = ZipperEx.next(zipper)
      #ZipperEx<{2, [3, 4]}>
      iex> zipper = ZipperEx.next(zipper)
      #ZipperEx<3>
      iex> zipper = ZipperEx.next(zipper)
      #ZipperEx<4>
      iex> zipper = ZipperEx.next(zipper)
      #ZipperEx<5>
      iex> zipper = ZipperEx.next(zipper)
      #ZipperEx<{1, [{2, [3, 4]}, 5]}>
      iex> ZipperEx.next(zipper)
      #ZipperEx<{1, [{2, [3, 4]}, 5]}>
      iex> ZipperEx.end?(zipper)
      true
  """
  @spec next(ZipperEx.t()) :: ZipperEx.t()
  def next(%ZipperEx{path: :end} = zipper), do: zipper

  def next(%ZipperEx{} = zipper) do
    case branch?(zipper) do
      true -> down(zipper)
      false -> next(zipper, :right)
    end
  end

  defp next(zipper, :right) do
    with nil <- right(zipper) do
      next(zipper, :up)
    end
  end

  defp next(zipper, :up) do
    case up(zipper) do
      nil -> %ZipperEx{zipper | path: :end}
      up -> next(up, :right)
    end
  end

  @doc """
  Returns the node from the given `zipper`.

  ## Examples

      iex> zipper = Support.Zipper.new({1, [{2, [3, 4]}, 5]})
      #ZipperEx<{1, [{2, [3, 4]}, 5]}>
      iex> ZipperEx.node(zipper)
      {1, [{2, [3, 4]}, 5]}
  """
  @spec node(ZipperEx.t()) :: tree()
  def node(%ZipperEx{loc: loc}), do: loc

  @doc """
  Returns the previours zipper for the given `zipper`.

  The function walks through the tree in the opposit direction as `next/1`.
  If no previous zipper is availble, `nil` will be returned.

  ## Examples

      iex> zipper = Support.Zipper.new({1, [{2, [3, 4]}, 5]})
      #ZipperEx<{1, [{2, [3, 4]}, 5]}>
      iex> zipper = ZipperEx.next(zipper)
      #ZipperEx<{2, [3, 4]}>
      iex> zipper = ZipperEx.next(zipper)
      #ZipperEx<3>
      iex> zipper = ZipperEx.prev(zipper)
      #ZipperEx<{2, [3, 4]}>
      iex> zipper = ZipperEx.prev(zipper)
      #ZipperEx<{1, [{2, [3, 4]}, 5]}>
      iex> ZipperEx.prev(zipper)
      nil
  """
  @spec prev(ZipperEx.t()) :: ZipperEx.t()
  def prev(%ZipperEx{path: :end} = zipper) do
    prev(%ZipperEx{zipper | path: nil}, :down)
  end

  def prev(%ZipperEx{} = zipper) do
    case left(zipper) do
      nil -> up(zipper)
      left -> prev(left, :down)
    end
  end

  defp prev(zipper, :down) do
    case branch?(zipper) do
      false -> zipper
      true -> zipper |> down() |> rightmost() |> prev(:down)
    end
  end

  @doc """
  Removes the given `zipper`.

  The function returns the previous `zipper`. If `remove/1` is called with an
  top level zipper an `ArgumentError` will be raised.

  ## Examples

      iex> zipper = Support.Zipper.new({1, [{2, [3, 4]}, 5]})
      #ZipperEx<{1, [{2, [3, 4]}, 5]}>
      iex> zipper = ZipperEx.down(zipper)
      #ZipperEx<{2, [3, 4]}>
      iex> ZipperEx.remove(zipper)
      #ZipperEx<{1, [5]}>
  """
  @spec remove(ZipperEx.t()) :: ZipperEx.t()
  def remove(%ZipperEx{path: nil}) do
    raise(ArgumentError, message: "can't remove the top level node")
  end

  def remove(%ZipperEx{left: [], path: path, right: right}) do
    %ZipperEx{path | loc: make_node(path, right)}
  end

  def remove(%ZipperEx{left: [next | left]} = zipper) do
    prev(%ZipperEx{zipper | left: left, loc: next}, :down)
  end

  @doc """
  Replaces the `zipper` with a `zipper` with the given `node`.

  ## Examples

      iex> zipper = Support.Zipper.new({1, [{2, [3, 4]}, 5]})
      #ZipperEx<{1, [{2, [3, 4]}, 5]}>
      iex> zipper |> ZipperEx.down() |> ZipperEx.replace(7) |> ZipperEx.root()
      {1, [7, 5]}
  """
  @spec replace(ZipperEx.t(), tree()) :: ZipperEx.t()
  def replace(%ZipperEx{} = zipper, node) do
    %ZipperEx{zipper | loc: node}
  end

  @doc """
  Returns the right sibling of the given `zipper`.

  Returns `nil` if the `zipper` doesn't have a right sibling.

  ## Examples

      iex> alias Support.TreeNode
      iex> zipper =
      ...>   TreeNode.new({1, [10, 11]})
      ...>   |> ZipperEx.new()
      ...>   |> ZipperEx.down()
      iex> zipper = ZipperEx.right(zipper)
      #ZipperEx<#TreeNode<11, []>>
      iex> ZipperEx.right(zipper)
      nil
      iex> zipper = ZipperEx.left(zipper)
      #ZipperEx<#TreeNode<10, []>>
      iex> ZipperEx.left(zipper)
      nil
  """
  @spec right(ZipperEx.t()) :: ZipperEx.t() | nil
  def right(%ZipperEx{right: []}), do: nil

  def right(%ZipperEx{right: [next | right]} = zipper) do
    %ZipperEx{zipper | loc: next, right: right, left: [zipper.loc | zipper.left]}
  end

  @doc """
  Returns the rightmost sibling of the given `zipper`.

  Returns the `zipper` himself if the given `zipper` is the rightmost sibling.

  ## Examples

      iex> alias Support.TreeNode
      iex> zipper =
      ...>   TreeNode.new({1, [10, 11, 12]})
      ...>   |> ZipperEx.new()
      ...>   |> ZipperEx.down()
      iex> zipper = ZipperEx.rightmost(zipper)
      #ZipperEx<#TreeNode<12, []>>
      iex> ZipperEx.rightmost(zipper)
      #ZipperEx<#TreeNode<12, []>>
  """
  @spec rightmost(ZipperEx.t()) :: ZipperEx.t()
  def rightmost(%ZipperEx{right: []} = zipper), do: zipper

  def rightmost(%ZipperEx{loc: loc, right: right, left: left} = zipper) do
    {right, [rightmost]} = Enum.split(right, -1)
    left = Enum.reverse(right) ++ [loc] ++ left
    %ZipperEx{zipper | loc: rightmost, right: [], left: left}
  end

  @doc """
  Returns the root node.

  ## Examples

      iex> alias Support.Zipper
      iex> zipper = Zipper.new({1, [{2, [3, 4]}, 5]})
      #ZipperEx<{1, [{2, [3, 4]}, 5]}>
      iex> zipper = zipper |> Zipper.down() |> Zipper.down()
      #ZipperEx<3>
      iex> Zipper.root(zipper)
      {1, [{2, [3, 4]}, 5]}
  """
  @spec root(ZipperEx.t()) :: tree()
  def root(%ZipperEx{} = zipper), do: zipper |> top() |> node()

  @doc """
  Returns the top level zipper.

  ## Examples

      iex> alias Support.Zipper
      iex> zipper = Zipper.new({1, [{2, [3, 4]}, 5]})
      #ZipperEx<{1, [{2, [3, 4]}, 5]}>
      iex> zipper = zipper |> Zipper.down() |> Zipper.down()
      #ZipperEx<3>
      iex> Zipper.top(zipper)
      #ZipperEx<{1, [{2, [3, 4]}, 5]}>
  """
  @spec top(ZipperEx.t()) :: ZipperEx.t()
  def top(%ZipperEx{path: path} = zipper) when path in [nil, :end], do: zipper

  def top(%ZipperEx{} = zipper), do: zipper |> up() |> top()

  @doc """
  Traverses the tree for the given `zipper` in depth-first pre-order and invokes
  `fun` for each zipper along the way.

  If the `zipper` is not at the top, just the subtree will be traversed.

  ## Examples

      iex> zipper = Support.Zipper.new({1, [{2, [3, 4]}, 5]})
      iex> ZipperEx.traverse(zipper, fn z ->
      ...>   ZipperEx.update(z, fn
      ...>     {value, children} -> {value + 100, children}
      ...>     value -> value + 200
      ...>   end)
      ...> end)
      #ZipperEx<{101, [{102, [203, 204]}, 205]}>

      iex> {1, [{2, [3, 4]}, 5]}
      ...> |> Support.Zipper.new()
      ...> |> ZipperEx.down()
      ...> |> ZipperEx.traverse(fn z ->
      ...>   ZipperEx.update(z, fn
      ...>     {value, children} -> {value + 100, children}
      ...>     value -> value + 200
      ...>   end)
      ...> end)
      ...> |> ZipperEx.root()
      {1, [{102, [203, 204]}, 5]}
  """
  @spec traverse(ZipperEx.t(), (ZipperEx.t() -> ZipperEx.t())) :: ZipperEx.t()
  def traverse(%ZipperEx{path: :end} = zipper, fun) when is_function(fun, 1) do
    do_traverse(%ZipperEx{zipper | path: nil}, fun)
  end

  def traverse(%ZipperEx{path: nil} = zipper, fun) when is_function(fun, 1) do
    do_traverse(zipper, fun)
  end

  def traverse(%ZipperEx{} = zipper, fun) when is_function(fun, 1) do
    replace(zipper, zipper |> new() |> do_traverse(fun) |> node())
  end

  defp do_traverse(%ZipperEx{path: :end} = zipper, _fun), do: zipper

  defp do_traverse(zipper, fun) do
    next = next(fun.(zipper))

    do_traverse(next, fun)
  end

  @doc """
  Traverses the tree for the given `zipper` in depth-first pre-order and invokes
  `fun` for each zipper along the way with the accumulator.

  If the `zipper` is not at the top, just the subtree will be traversed.

  ## Examples

      iex> zipper = Support.Zipper.new({1, [{2, [3, 4]}, 5]})
      iex> {zipper, acc} = ZipperEx.traverse(zipper, [], fn z, acc ->
      ...>   updated = ZipperEx.update(z, fn
      ...>     {value, children} -> {value + 100, children}
      ...>     value -> value + 200
      ...>   end)
      ...>   {updated, [ZipperEx.node(z) | acc]}
      ...> end)
      iex> zipper
      #ZipperEx<{101, [{102, [203, 204]}, 205]}>
      iex> acc
      [5, 4, 3, {2, [3, 4]}, {1, [{2, [3, 4]}, 5]}]
  """
  @spec traverse(
          ZipperEx.t(),
          acc,
          (ZipperEx.t(), acc -> {ZipperEx.t(), acc})
        ) :: {ZipperEx.t(), acc}
        when acc: term()
  def traverse(%ZipperEx{path: :end} = zipper, acc, fun) when is_function(fun, 2) do
    do_traverse(%ZipperEx{zipper | path: nil}, acc, fun)
  end

  def traverse(%ZipperEx{path: nil} = zipper, acc, fun) when is_function(fun, 2) do
    do_traverse(zipper, acc, fun)
  end

  def traverse(%ZipperEx{} = zipper, acc, fun) when is_function(fun, 2) do
    sub = new(zipper)
    {replacement, acc} = do_traverse(sub, acc, fun)
    {replace(zipper, node(replacement)), acc}
  end

  defp do_traverse(%ZipperEx{path: :end} = zipper, acc, _fun), do: {zipper, acc}

  defp do_traverse(%ZipperEx{} = zipper, acc, fun) do
    {zipper, acc} = fun.(zipper, acc)
    next = next(zipper)

    do_traverse(next, acc, fun)
  end

  @doc """
  Traverses the tree for the given `zipper` in depth-first pre-order until
  `fun` returns `{:halt, zipper}`. A subtree will be skipped if `fun` returns
  `{:skip, zipper}`.

  If the `zipper` is not at the top, just the subtree will be traversed.

  ## Examples

      iex> zipper = Support.Zipper.new({1, [{2, [3, 4]}, 5]})
      iex> ZipperEx.traverse_while(zipper, fn z ->
      ...>   case ZipperEx.node(z) do
      ...>     {2, _children} ->
      ...>       {:halt, z}
      ...>     _else ->
      ...>       {:cont, ZipperEx.update(z, fn
      ...>         {value, children} -> {value + 100, children}
      ...>         value -> value + 200
      ...>       end)}
      ...>   end
      ...> end)
      #ZipperEx<{101, [{2, [3, 4]}, 5]}>

      iex> zipper = Support.Zipper.new({1, [{2, [3, 4]}, 5]})
      iex> ZipperEx.traverse_while(zipper, fn z ->
      ...>   case ZipperEx.node(z) do
      ...>     {2, _children} ->
      ...>       {:skip, z}
      ...>     _else ->
      ...>       {:cont, ZipperEx.update(z, fn
      ...>         {value, children} -> {value + 100, children}
      ...>         value -> value + 200
      ...>       end)}
      ...>   end
      ...> end)
      #ZipperEx<{101, [{2, [3, 4]}, 205]}>
  """
  @spec traverse_while(
          ZipperEx.t(),
          (ZipperEx.t() ->
             {:cont, ZipperEx.t()}
             | {:halt, ZipperEx.t()}
             | {:skip, ZipperEx.t()})
        ) :: ZipperEx.t()
  def traverse_while(%ZipperEx{path: :end} = zipper, fun) when is_function(fun, 1) do
    do_traverse_while(%ZipperEx{zipper | path: nil}, fun)
  end

  def traverse_while(%ZipperEx{path: nil} = zipper, fun) when is_function(fun, 1) do
    do_traverse_while(zipper, fun)
  end

  def traverse_while(%ZipperEx{} = zipper, fun) when is_function(fun, 1) do
    replace(zipper, zipper |> new() |> do_traverse_while(fun) |> node())
  end

  defp do_traverse_while(%ZipperEx{path: :end} = zipper, _fun), do: zipper

  defp do_traverse_while(zipper, fun) do
    case fun.(zipper) do
      {:cont, cont} -> cont |> next() |> do_traverse_while(fun)
      {:skip, skip} -> skip |> next(:right) |> do_traverse_while(fun)
      {:halt, halt} -> halt |> top() |> Map.put(:path, :end)
    end
  end

  @doc """
  Traverses the tree for the given `zipper` in depth-first pre-order until
  `fun` returns `{:halt, zipper, acc}`. A subtree will be skipped if `fun`
  returns `{:skip, zipper, acc}`.

  If the `zipper` is not at the top, just the subtree will be traversed.

  ## Examples

      iex> zipper = Support.Zipper.new({1, [{2, [3, 4]}, {5, [6]}, 7]})
      iex> {zipper, acc} = ZipperEx.traverse_while(zipper, [], fn z, acc ->
      ...>   case ZipperEx.node(z) do
      ...>     {5, _children} ->
      ...>       {:halt, z, acc}
      ...>     _else ->
      ...>       updated = ZipperEx.update(z, fn
      ...>         {value, children} -> {value + 100, children}
      ...>         value -> value + 200
      ...>       end)
      ...>       {:cont, updated, [ZipperEx.node(z) | acc]}
      ...>   end
      ...> end)
      iex> zipper
      #ZipperEx<{101, [{102, [203, 204]}, {5, [6]}, 7]}>
      iex> acc
      [4, 3, {2, [3, 4]}, {1, [{2, [3, 4]}, {5, [6]}, 7]}]

      iex> zipper = Support.Zipper.new({1, [{2, [3, 4]}, {5, [6]}, 7]})
      iex> {zipper, acc} = ZipperEx.traverse_while(zipper, [], fn z, acc ->
      ...>   case ZipperEx.node(z) do
      ...>     {5, _children} ->
      ...>       {:skip, z, acc}
      ...>     _else ->
      ...>       updated = ZipperEx.update(z, fn
      ...>         {value, children} -> {value + 100, children}
      ...>         value -> value + 200
      ...>       end)
      ...>       {:cont, updated, [ZipperEx.node(z) | acc]}
      ...>   end
      ...> end)
      iex> zipper
      #ZipperEx<{101, [{102, [203, 204]}, {5, [6]}, 207]}>
      iex> acc
      [7, 4, 3, {2, [3, 4]}, {1, [{2, [3, 4]}, {5, [6]}, 7]}]
  """
  @spec traverse_while(
          ZipperEx.t(),
          acc,
          (ZipperEx.t(), acc ->
             {:cont, ZipperEx.t(), acc}
             | {:halt, ZipperEx.t(), acc}
             | {:skip, ZipperEx.t(), acc})
        ) :: {ZipperEx.t(), acc}
        when acc: term()
  def traverse_while(%ZipperEx{path: :end} = zipper, acc, fun) when is_function(fun, 2) do
    do_traverse_while(%ZipperEx{zipper | path: nil}, acc, fun)
  end

  def traverse_while(%ZipperEx{path: nil} = zipper, acc, fun) when is_function(fun, 2) do
    do_traverse_while(zipper, acc, fun)
  end

  def traverse_while(%ZipperEx{} = zipper, acc, fun) when is_function(fun, 2) do
    sub = new(zipper)
    {replacement, acc} = do_traverse_while(sub, acc, fun)
    {replace(zipper, node(replacement)), acc}
  end

  defp do_traverse_while(%ZipperEx{path: :end} = zipper, acc, _fun), do: {zipper, acc}

  defp do_traverse_while(zipper, acc, fun) do
    case fun.(zipper, acc) do
      {:cont, cont, acc} -> cont |> next() |> do_traverse_while(acc, fun)
      {:skip, skip, acc} -> skip |> next(:right) |> do_traverse_while(acc, fun)
      {:halt, halt, acc} -> {halt |> top() |> Map.put(:path, :end), acc}
    end
  end

  @doc """
  Returns the parent zipper of the given `zipper`.

  Returns `nil` if the `zipper` is the root.

  ## Examples

      iex> alias Support.TreeNode
      iex> zipper = ZipperEx.new(TreeNode.new({1, [2, 3]}))
      iex> zipper = ZipperEx.down(zipper)
      #ZipperEx<#TreeNode<2, []>>
      iex> ZipperEx.up(zipper)
      #ZipperEx<#TreeNode<1, [#TreeNode<2, []>, #TreeNode<3, []>]>>
  """
  @spec up(ZipperEx.t()) :: ZipperEx.t() | nil
  def up(%ZipperEx{path: path}) when path in [nil, :end], do: nil

  def up(%ZipperEx{left: left, loc: loc, path: path, right: right}) do
    children = Enum.reverse(left) ++ [loc] ++ right
    %ZipperEx{path | loc: make_node(path, children)}
  end

  @doc """
  Updates the node of the given `zipper`.

      iex> alias Support.TreeNode
      iex> zipper = ZipperEx.new(TreeNode.new({1, [2, 3]}))
      iex> zipper = ZipperEx.down(zipper)
      iex> zipper = ZipperEx.update(zipper, fn %TreeNode{} = node ->
      ...>   %{node | value: 99}
      ...> end)
      #ZipperEx<#TreeNode<99, []>>
      iex> ZipperEx.root(zipper)
      #TreeNode<1, [#TreeNode<99, []>, #TreeNode<3, []>]>
  """
  @spec update(ZipperEx.t(), (tree() -> tree())) :: ZipperEx.t()
  def update(%ZipperEx{loc: loc} = zipper, fun) when is_function(fun, 1) do
    %ZipperEx{zipper | loc: fun.(loc)}
  end

  defimpl Zipable do
    def branch?(%ZipperEx{module: module, loc: loc}) when not is_nil(module) do
      module.branch?(loc)
    end

    def children(%ZipperEx{module: module, loc: loc}) when not is_nil(module) do
      module.children(loc)
    end

    def make_node(%ZipperEx{module: module, loc: loc}, children)
        when not is_nil(module) do
      module.make_node(loc, children)
    end
  end

  defimpl Inspect do
    def inspect(zipper, _opts), do: "#ZipperEx<#{inspect(zipper.loc)}>"
  end

  defimpl Enumerable do
    def count(_zipper), do: {:error, __MODULE__}

    def member?(_zipper, _value), do: {:error, __MODULE__}

    def slice(_zipper), do: {:error, __MODULE__}

    def reduce(_zipper, {:halt, acc}, _fun), do: {:halted, acc}

    def reduce(%ZipperEx{path: :end}, {:cont, acc}, _fun), do: {:done, acc}

    def reduce(zipper, {:cont, acc}, fun) do
      reduce(ZipperEx.next(zipper), fun.(ZipperEx.node(zipper), acc), fun)
    end
  end
end
