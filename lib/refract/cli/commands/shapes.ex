defmodule Refract.CLI.Commands.Shapes do
  @moduledoc false

  use Refract.CLI.Command

  alias Refract.CLI.Answer
  alias Refract.CLI.Ctx
  alias Refract.CLI.ShapesFolder

  @impl Refract.CLI.Command
  def name, do: "shapes"

  @impl Refract.CLI.Command
  def summary, do: "the shapes in the shapes folder: name, version, file"

  @impl Refract.CLI.Command
  def example, do: "refract shapes --shapes ~/work/shapes"

  @impl Refract.CLI.Command
  def options, do: [ShapesFolder.option()]

  @impl Refract.CLI.Command
  def input, do: :none

  @impl Refract.CLI.Command
  def run(%Ctx{} = ctx) do
    with {:ok, folder} <- ShapesFolder.locate(ctx),
         do: {:answer, folder |> ShapesFolder.read_all() |> shapes_answer(folder)}
  end

  defp shapes_answer(entries, folder) do
    {loaded, unreadable} = Enum.split_with(entries, &match?({_file, {:ok, _shape}}, &1))

    %Answer{
      title: empty_title(loaded, folder),
      table:
        Refract.Table.new(
          nil,
          ["name", "version", "file"],
          %{},
          loaded |> Enum.map(&shape_row/1) |> Enum.sort_by(& &1["name"])
        ),
      footer: unreadable_text(unreadable)
    }
  end

  defp shape_row({file, {:ok, shape}}),
    do: %{"name" => shape.name, "version" => shape.version, "file" => file}

  defp empty_title([], folder), do: "no shapes in #{folder}"
  defp empty_title(_loaded, _folder), do: nil

  defp unreadable_text([]), do: nil

  defp unreadable_text(unreadable),
    do:
      Enum.map_join(unreadable, "\n", fn {file, {:error, why}} ->
        "#{file} cannot be read: #{why}"
      end)
end
