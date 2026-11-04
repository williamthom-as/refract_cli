defmodule Refract.CLI.Plugins do
  @moduledoc false

  @by_extension %{
    "xlsx" => "xlsx",
    "xlsm" => "xlsx",
    "json" => "json",
    "jsonl" => "json",
    "ndjson" => "json"
  }

  @spec readers() :: [module()]

  def readers, do: []

  @spec writers() :: [module()]

  def writers, do: []

  @spec plugin_for(String.t()) :: {:ok, String.t()} | :error

  def plugin_for(extension), do: Map.fetch(@by_extension, extension)
end
