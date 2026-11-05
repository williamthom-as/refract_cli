defmodule Refract.CLI.Input do
  @moduledoc false

  alias Refract.CLI.Opts
  alias Refract.CLI.Plugins
  alias Refract.Table.ColumnNames

  @enforce_keys [:name, :source, :reader, :opts]

  defstruct [:name, :source, :reader, :opts]

  @type t :: %__MODULE__{
          name: String.t(),
          source: Refract.source(),
          reader: module(),
          opts: keyword()
        }

  @spec resolve(Path.t() | nil, [String.t()], Refract.CLI.stdin()) ::
          {:ok, t()} | {:error, String.t()}

  def resolve(path, texts, stdin) do
    with {:ok, pairs} <- Opts.parse(texts, "--input-opts"),
         {:ok, name, source, reader} <- locate_source(path, stdin),
         {:ok, opts} <- Opts.to_options(pairs, reader.open_options(), reader_name(reader)) do
      {:ok, %__MODULE__{name: name, source: source, reader: reader, opts: opts}}
    end
  end

  @spec header(t()) :: {:ok, [Refract.cell()]} | {:error, String.t()}

  def header(%__MODULE__{name: name, source: source, reader: reader, opts: opts} = input) do
    with {:ok, lines} <- source |> reader.open(opts) |> read_failed(input),
         do: lines |> first_line() |> header_or_empty()
  rescue
    error in Refract.Errors.ParseError ->
      {:error, "cannot read #{name}: #{Exception.message(error)}"}
  end

  @spec rows(t()) :: {:ok, Enumerable.t()} | {:error, String.t()}

  def rows(%__MODULE__{source: source, reader: reader, opts: opts} = input),
    do: source |> reader.stream(opts) |> read_failed(input)

  @spec check_columns(t(), [Refract.cell()], [String.t()]) :: :ok | {:error, String.t()}

  def check_columns(%__MODULE__{name: name}, header, columns),
    do: columns |> Kernel.--(ColumnNames.from(header)) |> unknown_columns(name)

  defp unknown_columns([], _name), do: :ok

  defp unknown_columns([column | _rest], name),
    do: {:error, "no column #{column} in #{name}, see refract columns"}

  @spec read_error(t(), term()) :: String.t()

  def read_error(%__MODULE__{name: name}, reason), do: "cannot read #{name}: #{inspect(reason)}"

  defp first_line(lines), do: Enum.take(lines, 1)

  defp header_or_empty([header]), do: {:ok, header}
  defp header_or_empty([]), do: {:error, "the input is empty, no header"}

  defp read_failed({:ok, lines}, _input), do: {:ok, lines}
  defp read_failed({:error, reason}, input), do: {:error, read_error(input, reason)}

  defp locate_source(nil, {:pipe, device}),
    do: locate_source(nil, device |> IO.read(:eof) |> piped_text())

  defp locate_source(nil, :terminal), do: {:error, "no input, give --input FILE or pipe one in"}
  defp locate_source(nil, ""), do: {:error, "the input is empty, no header"}
  defp locate_source(nil, text), do: {:ok, "stdin", {:string, text}, Refract.CSV}

  defp locate_source(path, _stdin) do
    with {:ok, {reader, _entry_opts}} <- find_reader(path),
         :ok <- check_file_readable(path),
         do: {:ok, path, path, reader}
  end

  defp piped_text(:eof), do: ""
  defp piped_text(text), do: text

  defp find_reader(path) do
    with {:error, {:unsupported, extension}} <- Refract.Reader.for_path(path, Plugins.readers()),
         do: {:error, handle_no_reader(extension, Plugins.plugin_for(extension))}
  end

  defp handle_no_reader(extension, {:ok, plugin}),
    do: "no reader for .#{extension} files, add one with: refract plugins add #{plugin}"

  defp handle_no_reader(extension, :error), do: "no reader for .#{extension} files"

  defp check_file_readable(path), do: path |> File.stat() |> readable(path)

  defp readable({:ok, %File.Stat{type: :regular}}, _path), do: :ok

  defp readable({:ok, %File.Stat{type: type}}, path),
    do: {:error, "cannot read #{path}: a #{type}"}

  defp readable({:error, :enoent}, path), do: {:error, "cannot read #{path}: no such file"}

  defp readable({:error, reason}, path),
    do: {:error, "cannot read #{path}: #{:file.format_error(reason)}"}

  defp reader_name(reader),
    do: "the #{reader |> Module.split() |> List.last() |> String.downcase()} reader"
end
