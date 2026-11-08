defmodule Refract.CLI.ShapesFolder do
  @moduledoc false

  alias Refract.CLI.Ctx
  alias Refract.CLI.Option
  alias Refract.Shape

  @type entry :: {file :: String.t(), {:ok, Shape.t()} | {:error, String.t()}}

  @spec option() :: {atom(), Option.t()}

  def option do
    {:shapes,
     %Option{
       type: :string,
       value: "DIR",
       text: "the shapes folder, else REFRACT_SHAPES, else ~/.refract/shapes"
     }}
  end

  @spec locate(Ctx.t()) :: {:ok, Path.t()} | {:error, String.t()}

  def locate(%Ctx{options: options, env: env}),
    do: options |> Keyword.get(:shapes) |> chosen_folder(env) |> existing_folder()

  @spec read_all(Path.t()) :: [entry()]

  def read_all(folder) do
    folder
    |> File.ls!()
    |> Enum.filter(&(Path.extname(&1) in [".yml", ".yaml"]))
    |> Enum.sort()
    |> Enum.map(&{&1, folder |> Path.join(&1) |> Shape.load() |> loaded()})
  end

  @spec fetch(Path.t(), String.t()) :: {:ok, String.t(), Shape.t()} | {:error, String.t()}

  def fetch(folder, name),
    do: folder |> read_all() |> Enum.filter(&named?(&1, name)) |> fetched(folder, name)

  defp chosen_folder(nil, %{"REFRACT_SHAPES" => folder}), do: folder
  defp chosen_folder(nil, %{"HOME" => home}), do: Path.join([home, ".refract", "shapes"])
  defp chosen_folder(nil, _env), do: nil
  defp chosen_folder(folder, _env), do: folder

  defp existing_folder(nil),
    do: {:error, "no shapes folder, set REFRACT_SHAPES or give --shapes DIR"}

  defp existing_folder(folder), do: folder |> File.dir?() |> folder_result(folder)

  defp folder_result(true, folder), do: {:ok, folder}

  defp folder_result(false, folder),
    do: {:error, "no shapes folder #{folder}, set REFRACT_SHAPES or give --shapes DIR"}

  defp named?({_file, {:ok, %Shape{name: name}}}, name), do: true
  defp named?(_entry, _name), do: false

  defp fetched([{file, {:ok, shape}}], _folder, _name), do: {:ok, file, shape}

  defp fetched([], folder, name),
    do: {:error, "no shape #{name} in #{folder}, see refract shapes"}

  defp fetched(entries, _folder, name),
    do:
      {:error,
       "shape #{name} is in #{length(entries)} files: #{Enum.map_join(entries, ", ", &elem(&1, 0))}"}

  defp loaded({:ok, shape}), do: {:ok, shape}
  defp loaded({:error, reason}), do: {:error, Shape.describe_error(reason)}
end
