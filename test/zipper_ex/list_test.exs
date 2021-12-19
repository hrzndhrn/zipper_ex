defmodule ZipperEx.ListTest do
  use ExUnit.Case

  doctest ZipperEx.List

  describe "new/1" do
    test "returns a new zipper for lists" do
      assert ZipperEx.List.new([1, 2]) == %ZipperEx{
               left: [],
               loc: [1, 2],
               module: ZipperEx.List,
               path: nil,
               right: []
             }
    end
  end

  describe "traverse/2" do
    test "returns an updated list" do
      zipper = ZipperEx.List.new([11, [21, 22, [a: 23], [31, 32], 24]])

      assert zipper
             |> ZipperEx.traverse(fn zipper ->
               ZipperEx.update(zipper, fn node ->
                 case is_number(node) do
                   true -> node + 100
                   false -> node
                 end
               end)
             end)
             |> ZipperEx.node() == [111, [121, 122, [a: 23], [131, 132], 124]]
    end
  end
end
