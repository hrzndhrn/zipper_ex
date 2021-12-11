defmodule ZipperEx.MapTest do
  use ExUnit.Case

  doctest ZipperEx.Map

  describe "new/1" do
    test "returns a new zipper for maps" do
      tree = %{"a" => 1, "b" => %{"x" => 2}}

      assert ZipperEx.Map.new(tree) == %ZipperEx{
               left: [],
               location: tree,
               module: ZipperEx.Map,
               path: nil,
               right: []
             }
    end
  end

  describe "map/2" do
    test "returns a mapped map" do
      map = ZipperEx.Map.new(%{"a" => 1, "b" => %{"x" => 2}})

      mapped =
        ZipperEx.map(map, fn
          {key, value} when is_integer(value) ->
            {String.upcase(key), value + 10}

          {key, value} ->
            {String.upcase(key), value}

          node ->
            node
        end)

      assert ZipperEx.node(mapped) == %{"A" => 11, "B" => %{"X" => 12}}
    end
  end
end
