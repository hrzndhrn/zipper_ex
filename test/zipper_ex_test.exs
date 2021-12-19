defmodule ZipperExTest do
  use ExUnit.Case

  doctest ZipperEx

  alias Support.TreeNode
  alias Support.Zipper

  describe "new/1" do
    test "returns a new zipper" do
      tree = TreeNode.new({1, [2]})

      assert ZipperEx.new(tree) == %ZipperEx{
               left: [],
               loc: tree,
               module: nil,
               path: nil,
               right: []
             }
    end

    test "returns a new zipper for a module-zipper" do
      tree = {1, [2]}

      assert Zipper.new(tree) == %ZipperEx{
               left: [],
               loc: tree,
               module: Zipper,
               path: nil,
               right: []
             }
    end

    test "returns a new zipper form a root zipper" do
      tree = {1, [2]}
      zipper = Zipper.new(tree)

      assert ZipperEx.new(zipper) == zipper
    end

    test "returns a new zipper form a zipper" do
      tree = {1, [{2, [3]}]}
      zipper = Zipper.new(tree)

      assert zipper |> ZipperEx.next() |> ZipperEx.new() |> Zipper.node() == {2, [3]}
    end
  end

  describe "node/1" do
    test "returns the current node (protocol)" do
      tree = TreeNode.new({1, [2]})
      zipper = ZipperEx.new(tree)

      assert ZipperEx.node(zipper) == tree
    end

    test "returns the current node (module)" do
      tree = {1, [2]}
      zipper = Zipper.new(tree)

      assert Zipper.node(zipper) == tree
    end
  end

  describe "next/1" do
    test "returns the next zipper (protocol)" do
      tree = TreeNode.new({1, [2]})
      zipper = ZipperEx.new(tree)

      assert ZipperEx.next(zipper) == %ZipperEx{
               left: [],
               loc: %Support.TreeNode{children: [], value: 2},
               module: nil,
               path: %ZipperEx{
                 left: [],
                 loc: %Support.TreeNode{
                   children: [%Support.TreeNode{children: [], value: 2}],
                   value: 1
                 },
                 module: nil,
                 path: nil,
                 right: []
               },
               right: []
             }
    end

    test "returns the next zipper (module)" do
      tree = {1, [2]}
      zipper = Zipper.new(tree)

      assert Zipper.next(zipper) == %ZipperEx{
               left: [],
               loc: 2,
               module: Support.Zipper,
               path: %ZipperEx{
                 left: [],
                 loc: {1, [2]},
                 module: Support.Zipper,
                 path: nil,
                 right: []
               },
               right: []
             }
    end

    test "returns an end zipper if no more nodes are available" do
      tree = TreeNode.new({1, [2]})
      zipper = ZipperEx.new(tree)

      ended = zipper |> ZipperEx.next() |> ZipperEx.next()
      assert ended == %ZipperEx{zipper | path: :end}
      assert ZipperEx.next(ended) == %ZipperEx{zipper | path: :end}
    end
  end

  describe "prev/1" do
    test "returns the previous zipper" do
      tree = {
        1,
        [
          11,
          {12,
           [
             21,
             {22,
              [
                31,
                {32, [41, 42]}
              ]}
           ]},
          13
        ]
      }

      zipper = Zipper.new(tree)
      assert_prev(zipper)

      traversed = Zipper.traverse(zipper, &Function.identity/1)

      assert traversed |> Zipper.prev() |> Zipper.node() == 13
      assert Zipper.prev(zipper) == nil
    end

    defp assert_prev(zipper) do
      next = Zipper.next(zipper)

      case Zipper.end?(next) do
        true ->
          :ok

        false ->
          assert Zipper.prev(next) == zipper
          assert_prev(next)
      end
    end

    test "from :end to nil" do
      zipper = ZipperEx.List.new([1, [2]])

      ended =
        zipper
        |> ZipperEx.next()
        |> ZipperEx.next()
        |> ZipperEx.next()
        |> ZipperEx.next()

      assert ZipperEx.end?(ended) == true

      back =
        ended
        |> ZipperEx.prev()
        |> assert_node(2)
        |> ZipperEx.prev()
        |> assert_node([2])
        |> ZipperEx.prev()
        |> assert_node(1)
        |> ZipperEx.prev()
        |> assert_node([1, [2]])
        |> ZipperEx.prev()

      assert back == nil
    end

    defp assert_node(zipper, expected) do
      assert ZipperEx.node(zipper) == expected
      zipper
    end
  end

  describe "down/1" do
    test "returns children" do
      tree = TreeNode.new({1, [2]})
      zipper = ZipperEx.new(tree)

      assert zipper |> ZipperEx.down() |> ZipperEx.node() == %TreeNode{value: 2}
    end

    test "returns nil if no childrens are available" do
      tree = TreeNode.new({1, [2]})
      zipper = ZipperEx.new(tree)

      assert zipper |> ZipperEx.down() |> ZipperEx.node() == %TreeNode{value: 2}
      assert zipper |> ZipperEx.down() |> ZipperEx.down() == nil
    end
  end

  describe "up/1" do
    test "returns the parent of the current node (protocol)" do
      tree = TreeNode.new({1, [2]})
      zipper = ZipperEx.new(tree)

      assert zipper |> ZipperEx.next() |> ZipperEx.up() |> ZipperEx.node() == tree
    end

    test "returns nil if no parent is available (protocol)" do
      tree = TreeNode.new({1, [2]})
      zipper = ZipperEx.new(tree)

      assert ZipperEx.up(zipper) == nil
    end

    test "returns the parent of the current node (module)" do
      tree = {1, [2]}
      zipper = Zipper.new(tree)

      assert zipper |> Zipper.next() |> Zipper.up() |> Zipper.node() == tree
    end

    test "returns nil if no parent is available (module)" do
      tree = {1, [2]}
      zipper = Zipper.new(tree)

      assert Zipper.up(zipper) == nil

      zipper = %{zipper | path: :end}

      assert Zipper.up(zipper) == nil
    end
  end

  describe "top/1" do
    test "returns the root zipper" do
      tree = {1, [11, {12, [{21, [31, 32]}, 22]}, 13]}
      zipper = Zipper.new(tree)

      inside =
        zipper
        |> Zipper.down()
        |> Zipper.right()
        |> Zipper.down()

      assert Zipper.node(inside) == {21, [31, 32]}
      assert inside |> Zipper.top() |> Zipper.node() == tree
    end

    test "returns the root of an ended zipper" do
      tree = {1, [11, {12, [{21, [31, 32]}, 22]}, 13]}
      zipper = Zipper.new(tree)
      zipper = %{zipper | path: :end}

      assert Zipper.top(zipper) == zipper
    end
  end

  describe "branch?/1" do
    test "returns true if the current node is a branch (protocol)" do
      tree = TreeNode.new({1, [2]})
      zipper = ZipperEx.new(tree)

      assert ZipperEx.branch?(zipper) == true
    end

    test "returns false if the current node is not a branch (protocol)" do
      tree = TreeNode.new({1, [2]})
      zipper = ZipperEx.new(tree)

      assert zipper |> ZipperEx.next() |> ZipperEx.branch?() == false
    end

    test "returns true if the current node is a branch (module)" do
      zipper = Zipper.new({1, [2]})

      assert Zipper.branch?(zipper) == true
    end

    test "returns false if the current node is not a branch (moudle)" do
      zipper = Zipper.new({1, [2]})

      assert zipper |> Zipper.next() |> Zipper.branch?() == false
    end
  end

  describe "children/1" do
    test "returns the children (protocol)" do
      tree = TreeNode.new({1, [2]})
      zipper = ZipperEx.new(tree)

      assert ZipperEx.children(zipper) == [%TreeNode{value: 2}]
    end

    test "returns the children for (module)" do
      zipper = Zipper.new({1, [2]})

      assert Zipper.children(zipper) == [2]
    end
  end

  describe "traverse/2" do
    test "runs through the tree" do
      zipper = Zipper.new({1, [11, {12, [{21, [31]}, 22]}]})

      fun = fn sub ->
        ZipperEx.update(sub, fn
          22 -> {222, [55]}
          {value, children} -> {value + 100, children}
          value -> value + 100
        end)
      end

      updated = Zipper.traverse(zipper, fun)

      assert updated == %ZipperEx{
               left: [],
               loc: {101, [111, {112, [{121, [131]}, {222, [155]}]}]},
               module: Support.Zipper,
               path: :end,
               right: []
             }

      assert Zipper.traverse(updated, fun) == %ZipperEx{
               left: [],
               loc: {201, [211, {212, [{221, [231]}, {322, [255]}]}]},
               module: Support.Zipper,
               path: :end,
               right: []
             }
    end

    test "runs through the updating odd values" do
      zipper = Zipper.new({1, [{11, [21, 22]}, {12, [23, 24]}, {13, [25, 26]}]})

      add = 100

      fun = fn sub ->
        case Zipper.node(sub) do
          {value, _children} when rem(value, 2) == 1 ->
            Zipper.update(sub, fn {value, children} -> {value + add, children} end)

          value when rem(value, 2) == 1 ->
            Zipper.update(sub, fn value -> value + add end)

          _else ->
            sub
        end
      end

      updated = Zipper.traverse(zipper, fun)

      assert Zipper.node(updated) == {
               101,
               [{111, [121, 22]}, {12, [123, 24]}, {113, [125, 26]}]
             }
    end

    test "traverses a subtree" do
      zipper = Zipper.new({1, [{11, [21, 22]}, {12, [23, 24]}, {13, [25, 26]}]})

      add = 100

      fun = fn sub ->
        Zipper.update(sub, fn
          {value, children} -> {value + add, children}
          value -> value + add
        end)
      end

      updated = zipper |> Zipper.down() |> Zipper.traverse(fun)

      assert Zipper.root(updated) == {
               1,
               [{111, [121, 122]}, {12, [23, 24]}, {13, [25, 26]}]
             }
    end
  end

  describe "traverse_while/2" do
    test "skips branches" do
      zipper = Zipper.new({1, [{11, [21, 22]}, {12, [23, 24]}, {13, [25, 26]}]})

      add = 100

      fun = fn sub ->
        case Zipper.node(sub) do
          {value, _children} when rem(value, 2) == 1 ->
            {:cont, Zipper.update(sub, fn {value, children} -> {value + add, children} end)}

          value when rem(value, 2) == 1 ->
            {:cont, Zipper.update(sub, fn value -> value + add end)}

          _else ->
            {:skip, sub}
        end
      end

      updated = Zipper.traverse_while(zipper, fun)

      assert Zipper.node(updated) == {
               101,
               [{111, [121, 22]}, {12, [23, 24]}, {113, [125, 26]}]
             }
    end

    test "halts traversing" do
      zipper = Zipper.new({1, [{11, [21, 22]}, {12, [23, 24]}, {13, [25, 26]}]})

      add = 100

      fun = fn sub ->
        case Zipper.node(sub) do
          {value, _children} when rem(value, 2) == 1 ->
            {:cont, Zipper.update(sub, fn {value, children} -> {value + add, children} end)}

          value when rem(value, 2) == 1 ->
            {:cont, Zipper.update(sub, fn value -> value + add end)}

          _else ->
            {:halt, sub}
        end
      end

      updated = Zipper.traverse_while(zipper, fun)

      assert Zipper.node(updated) == {101, [{111, [121, 22]}, {12, [23, 24]}, {13, [25, 26]}]}
    end

    test "traverses an ended zipper" do
      zipper = Zipper.new({1, [2]})
      zipper = %ZipperEx{zipper | path: :end}

      zipper =
        Zipper.traverse_while(zipper, fn z ->
          case Zipper.node(z) do
            {_value, _children} -> {:cont, z}
            _value -> {:cont, Zipper.update(z, fn value -> value * 2 end)}
          end
        end)

      assert Zipper.root(zipper) == {1, [4]}
    end

    test "traverses a subtree" do
      zipper = Zipper.new({1, [{2, [3, 4]}, {5, [6]}]})

      zipper =
        zipper
        |> Zipper.down()
        |> Zipper.traverse_while(fn z ->
          {:cont,
           Zipper.update(z, fn
             {value, children} -> {value * 2, children}
             value -> value * 3
           end)}
        end)

      assert Zipper.root(zipper) == {1, [{4, [9, 12]}, {5, [6]}]}
    end
  end

  describe "traverse/3" do
    test "runs through the tree" do
      zipper =
        Zipper.new(
          {1,
           [
             11,
             12,
             {13,
              [
                {21,
                 [
                   31
                 ]},
                22
              ]},
             14,
             {15,
              [
                23
              ]}
           ]}
        )

      assert Zipper.traverse(zipper, [], fn sub, acc ->
               case ZipperEx.node(sub) do
                 {value, _children} -> {sub, [value | acc]}
                 value -> {sub, [value | acc]}
               end
             end) == {
               %ZipperEx{zipper | path: :end},
               [23, 15, 14, 22, 31, 21, 13, 12, 11, 1]
             }
    end

    test "runs throught the tree for a list-zipper" do
      zipper = ZipperEx.List.new([1, [2, [3, 4], 5], [6, 7]])

      {_zipper, acc} =
        ZipperEx.traverse(zipper, [], fn zipper, acc ->
          {zipper, [ZipperEx.node(zipper) | acc]}
        end)

      assert Enum.reverse(acc) == [
               [1, [2, [3, 4], 5], [6, 7]],
               1,
               [2, [3, 4], 5],
               2,
               [3, 4],
               3,
               4,
               5,
               [6, 7],
               6,
               7
             ]
    end

    test "runs throught the tree for a list-zipper for an ended zipper" do
      zipper = ZipperEx.List.new([1, [2, [3, 4], 5], [6, 7]])

      zipper = %ZipperEx{zipper | path: :end}

      {_zipper, acc} =
        ZipperEx.traverse(zipper, [], fn zipper, acc ->
          {zipper, [ZipperEx.node(zipper) | acc]}
        end)

      assert Enum.reverse(acc) == [
               [1, [2, [3, 4], 5], [6, 7]],
               1,
               [2, [3, 4], 5],
               2,
               [3, 4],
               3,
               4,
               5,
               [6, 7],
               6,
               7
             ]
    end

    test "traverses a subtree" do
      zipper = Zipper.new({42, [{10, [{11, [21, 22]}, {12, [23, 24]}, {13, [25, 26]}]}]})

      add = 100

      fun = fn sub, acc ->
        case Zipper.node(sub) do
          {value, _children} ->
            {sub, [value + add | acc]}

          value when is_integer(value) ->
            {sub, [value | acc]}
        end
      end

      {_zipper, acc} = zipper |> Zipper.down() |> Zipper.traverse([], fun)

      assert acc == [26, 25, 113, 24, 23, 112, 22, 21, 111, 110]
    end
  end

  describe "traverse_while/3" do
    test "traverses a subtree" do
      zipper = Zipper.new({42, [{10, [{11, [21, 22]}, {12, [23, 24]}, {13, [25, 26]}]}]})

      add = 100

      fun = fn sub, acc ->
        case Zipper.node(sub) do
          {value, _children} when rem(value, 2) == 0 ->
            {:cont, sub, [value + add | acc]}

          value when is_integer(value) ->
            {:cont, sub, [value | acc]}

          _else ->
            {:skip, sub, acc}
        end
      end

      {_zipper, acc} = zipper |> Zipper.down() |> Zipper.traverse_while([], fun)

      assert acc == [24, 23, 112, 110]
    end

    test "traverses an ended zipper" do
      zipper = Zipper.new({1, [2]})
      zipper = %ZipperEx{zipper | path: :end}

      {_zipper, acc} =
        Zipper.traverse_while(zipper, [], fn z, acc ->
          case Zipper.node(z) do
            {value, _children} -> {:cont, z, [value * 2 | acc]}
            value -> {:cont, z, [value * 3 | acc]}
          end
        end)

      assert acc == [6, 2]
    end
  end

  describe "append_child/2" do
    test "appends a child (module)" do
      zipper = Zipper.new({1, [2]})

      assert zipper |> Zipper.append_child(3) |> Zipper.node() == {1, [2, 3]}
    end

    test "appends a child (protocol)" do
      tree = TreeNode.new({1, [2]})
      zipper = ZipperEx.new(tree)

      assert zipper
             |> ZipperEx.append_child(TreeNode.new(3))
             |> ZipperEx.node() ==
               TreeNode.new({1, [2, 3]})
    end

    test "appends a child to a leaf (module)" do
      zipper = Zipper.new({1, [2]})

      assert zipper
             |> Zipper.down()
             |> Zipper.append_child(3)
             |> Zipper.top()
             |> Zipper.node() ==
               {1, [{2, [3]}]}
    end

    test "appends a child to a leaf (protocol)" do
      tree = TreeNode.new({1, [2]})
      zipper = ZipperEx.new(tree)

      assert zipper
             |> ZipperEx.down()
             |> ZipperEx.append_child(TreeNode.new(3))
             |> ZipperEx.top()
             |> ZipperEx.node() ==
               TreeNode.new({1, [{2, [3]}]})
    end
  end

  describe "insert_child/2" do
    test "appends a child (module)" do
      zipper = Zipper.new({1, [2]})

      assert zipper |> Zipper.insert_child(3) |> Zipper.node() == {1, [3, 2]}
    end

    test "appends a child (protocol)" do
      tree = TreeNode.new({1, [2]})
      zipper = ZipperEx.new(tree)

      assert zipper
             |> ZipperEx.insert_child(TreeNode.new(3))
             |> ZipperEx.node() ==
               TreeNode.new({1, [3, 2]})
    end

    test "appends a child to a leaf (module)" do
      zipper = Zipper.new({1, [2]})

      assert zipper
             |> Zipper.down()
             |> Zipper.insert_child(3)
             |> Zipper.top()
             |> Zipper.node() ==
               {1, [{2, [3]}]}
    end

    test "appends a child to a leaf (protocol)" do
      tree = TreeNode.new({1, [2]})
      zipper = ZipperEx.new(tree)

      assert zipper
             |> ZipperEx.down()
             |> ZipperEx.insert_child(TreeNode.new(3))
             |> ZipperEx.top()
             |> ZipperEx.node() ==
               TreeNode.new({1, [{2, [3]}]})
    end
  end

  describe "insert_right/2" do
    test "insert a child to the right (module)" do
      zipper = Zipper.new({1, [2]})

      assert zipper
             |> Zipper.down()
             |> Zipper.insert_right(3)
             |> Zipper.top()
             |> Zipper.node() == {1, [2, 3]}
    end

    test "insert a child to the right before other right siblings (module)" do
      zipper = Zipper.new({1, [10, 11, 13]})

      assert zipper
             |> Zipper.down()
             |> Zipper.right()
             |> Zipper.insert_right(12)
             |> Zipper.top()
             |> Zipper.node() == {1, [10, 11, 12, 13]}
    end

    test "inserts a child to the right (protocol)" do
      tree = TreeNode.new({1, [2]})
      zipper = ZipperEx.new(tree)

      assert zipper
             |> ZipperEx.down()
             |> ZipperEx.insert_right(TreeNode.new(3))
             |> ZipperEx.top()
             |> ZipperEx.node() ==
               TreeNode.new({1, [2, 3]})
    end

    test "inserts a child to the right before other right siblings (protocol)" do
      tree = TreeNode.new({1, [10, 11, 13]})
      zipper = ZipperEx.new(tree)

      assert zipper
             |> ZipperEx.down()
             |> ZipperEx.right()
             |> ZipperEx.insert_right(TreeNode.new(12))
             |> ZipperEx.top()
             |> ZipperEx.node() ==
               TreeNode.new({1, [10, 11, 12, 13]})
    end

    test "raise an ArgumentError on the top level" do
      tree = TreeNode.new({1, []})
      zipper = ZipperEx.new(tree)
      message = "can't insert right sibling at the top level"

      assert_raise ArgumentError, message, fn ->
        ZipperEx.insert_right(zipper, TreeNode.new(5))
      end
    end
  end

  describe "right/1" do
    test "returns the zipper to the right" do
      zipper = Zipper.new({1, [11, 12, 13]})

      assert zipper |> Zipper.down() |> Zipper.node() == 11
      assert zipper |> Zipper.down() |> Zipper.right() |> Zipper.node() == 12
      assert zipper |> Zipper.down() |> Zipper.right() |> Zipper.right() |> Zipper.node() == 13
    end

    test "returns nil if no right sibling is available" do
      zipper = Zipper.new({1, [11]})

      assert zipper |> Zipper.down() |> Zipper.right() == nil
    end
  end

  describe "rightmost/1" do
    test "returns the rightmost zipper" do
      zipper =
        {1, [11, 12, 13]}
        |> Zipper.new()
        |> Zipper.down()

      assert Zipper.node(zipper) == 11
      assert zipper |> Zipper.rightmost() |> Zipper.node() == 13
      assert zipper |> Zipper.rightmost() |> Zipper.rightmost() == Zipper.rightmost(zipper)
    end

    test "prevserves order of childs" do
      tree = {1, [11, 12, 13]}

      zipper =
        tree
        |> Zipper.new()
        |> Zipper.down()
        |> Zipper.right()

      rightmost = Zipper.rightmost(zipper)
      assert Zipper.node(rightmost) == 13
      assert rightmost |> Zipper.top() |> Zipper.node() == tree
    end
  end

  describe "left/1" do
    test "returns the zipper to the right" do
      zipper =
        {1, [11, 12, 13]}
        |> Zipper.new()
        |> Zipper.down()
        |> Zipper.right()
        |> Zipper.right()

      assert zipper |> Zipper.left() |> Zipper.node() == 12
      assert zipper |> Zipper.left() |> Zipper.left() |> Zipper.node() == 11
    end

    test "returns nil if no right sibling is available" do
      zipper =
        {1, [11, 12, 13]}
        |> Zipper.new()
        |> Zipper.down()

      assert Zipper.left(zipper) == nil
    end
  end

  describe "leftmost/1" do
    test "returns the leftmost zipper" do
      zipper =
        {1, [11, 12, 13]}
        |> Zipper.new()
        |> Zipper.down()
        |> Zipper.right()
        |> Zipper.right()

      assert Zipper.node(zipper) == 13
      assert zipper |> Zipper.leftmost() |> Zipper.node() == 11
      assert zipper |> Zipper.leftmost() |> Zipper.leftmost() == Zipper.leftmost(zipper)
    end

    test "prevserves order of childs" do
      tree = {1, [11, 12, 13]}

      zipper =
        tree
        |> Zipper.new()
        |> Zipper.down()
        |> Zipper.right()

      leftmost = Zipper.leftmost(zipper)
      assert Zipper.node(leftmost) == 11
      assert leftmost |> Zipper.top() |> Zipper.node() == tree
    end
  end

  describe "insert_left/2" do
    test "insert a child to the left (module)" do
      zipper = Zipper.new({1, [2]})

      assert zipper
             |> Zipper.down()
             |> Zipper.insert_left(3)
             |> Zipper.top()
             |> Zipper.node() == {1, [3, 2]}
    end

    test "insert a child to the left before other left siblings (module)" do
      zipper = Zipper.new({1, [10, 11, 13]})

      assert zipper
             |> Zipper.down()
             |> Zipper.right()
             |> Zipper.right()
             |> Zipper.insert_left(12)
             |> Zipper.top()
             |> Zipper.node() == {1, [10, 11, 12, 13]}
    end

    test "inserts a child to the left (protocol)" do
      tree = TreeNode.new({1, [2]})
      zipper = ZipperEx.new(tree)

      assert zipper
             |> ZipperEx.down()
             |> ZipperEx.insert_left(TreeNode.new(3))
             |> ZipperEx.top()
             |> ZipperEx.node() ==
               TreeNode.new({1, [3, 2]})
    end

    test "inserts a child to the left before other left siblings (protocol)" do
      tree = TreeNode.new({1, [10, 11, 13]})
      zipper = ZipperEx.new(tree)

      assert zipper
             |> ZipperEx.down()
             |> ZipperEx.right()
             |> ZipperEx.right()
             |> ZipperEx.insert_left(TreeNode.new(12))
             |> ZipperEx.top()
             |> ZipperEx.node() ==
               TreeNode.new({1, [10, 11, 12, 13]})
    end

    test "raise an ArgumentError on the top level" do
      tree = TreeNode.new({1, []})
      zipper = ZipperEx.new(tree)
      message = "can't insert left sibling at the top level"

      assert_raise ArgumentError, message, fn ->
        ZipperEx.insert_left(zipper, TreeNode.new(5))
      end
    end
  end

  describe "find/2" do
    test "returns zipper (module)" do
      zipper = Zipper.new({1, [10, {11, [{21, [31, 32]}]}, 12]})

      found =
        Zipper.find(zipper, fn zipper ->
          case Zipper.node(zipper) do
            {21, _children} -> true
            _else -> false
          end
        end)

      assert Zipper.node(found) == {21, [31, 32]}
    end

    test "returns nil for nil" do
      assert ZipperEx.find(nil, &Function.identity/1) == nil
    end
  end

  describe "replace/1" do
    test "replaced the current node" do
      tree = {1, [11, {12, [21, 22]}, 13]}

      zipper =
        tree
        |> Zipper.new()
        |> Zipper.down()
        |> Zipper.right()

      assert zipper |> Zipper.replace({98, [99]}) |> Zipper.root() == {1, [11, {98, [99]}, 13]}
    end
  end

  describe "remove/1" do
    test "removes the current node" do
      tree = {1, [11, {12, [21, 22]}, 13]}

      zipper =
        tree
        |> Zipper.new()
        |> Zipper.down()
        |> Zipper.right()

      assert zipper |> Zipper.remove() |> Zipper.top() |> Zipper.node() == {1, [11, 13]}
    end

    test "selects the previous zipper" do
      tree = {1, [11, {12, [21, 22]}, 13]}

      zipper =
        tree
        |> Zipper.new()
        |> Zipper.down()
        |> Zipper.right()
        |> Zipper.right()

      assert zipper |> Zipper.remove() |> Zipper.node() ==
               zipper |> Zipper.prev() |> Zipper.node()
    end

    test "goes up" do
      tree = {1, [11, {12, [21, 22]}, 13]}

      zipper =
        tree
        |> Zipper.new()
        |> Zipper.down()

      assert zipper |> Zipper.remove() |> Zipper.node() == {1, [{12, [21, 22]}, 13]}
    end

    test "raises an exception on the top level" do
      tree = {1, [11, {12, [21, 22]}, 13]}
      zipper = Zipper.new(tree)
      message = "can't remove the top level node"

      assert_raise ArgumentError, message, fn ->
        Zipper.remove(zipper)
      end
    end
  end

  describe "protocols:" do
    test "inspect/1" do
      assert {1, [2]} |> Zipper.new() |> inspect() == "#ZipperEx<{1, [2]}>"
    end

    test "map/2" do
      assert {1, [2]} |> Zipper.new() |> Enum.map(&Function.identity/1) == [{1, [2]}, 2]
    end

    test "count/1" do
      assert {1, [{2, [3]}]} |> Zipper.new() |> Enum.count() == 3
    end

    test "member/2" do
      assert {1, [{2, [3]}, 4]} |> Zipper.new() |> Enum.member?(4) == true
    end

    test "slice/2" do
      assert {1, [{2, [3]}, 4]} |> Zipper.new() |> Enum.slice(1..3) == [{2, [3]}, 3, 4]
    end

    test "reduce_while/3" do
      assert {1, [{2, [3]}, 4]}
             |> Zipper.new()
             |> Enum.reduce_while([], fn
               _item, [_one, _two] = acc -> {:halt, acc}
               item, acc -> {:cont, [item | acc]}
             end) == [{2, [3]}, {1, [{2, [3]}, 4]}]
    end
  end
end
