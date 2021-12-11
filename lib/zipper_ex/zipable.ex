defprotocol ZipperEx.Zipable do
  @moduledoc """
  `Zipable` protocol used by `ZipperEx`.

  See `ZipperEx` for an example.
  """

  @fallback_to_any true

  @doc """
  Returns `true` if the given `node` is a branch.
  """
  @spec branch?(ZipperEx.t()) :: boolean()
  def branch?(node)

  @doc """
  Returns the children of the given `node`.
  """
  @spec children(ZipperEx.t()) :: [ZipperEx.tree()]
  def children(node)

  @doc """
  Creates a `node` from the given `node` and `children`.
  """
  @spec make_node(ZipperEx.t(), [ZipperEx.tree()]) :: ZipperEx.t()
  def make_node(node, children)
end
