defmodule Refract.CLI.Output do
  @moduledoc false

  alias Refract.CLI.Answer
  alias Refract.CLI.Ctx
  alias Refract.CLI.Layout
  alias Refract.CLI.Opts
  alias Refract.CLI.Plugins

  @spec render(Refract.CLI.Command.result(), Ctx.t()) :: {:ok, 0 | 1} | {:error, String.t()}

  def render({:answer, %Answer{} = answer}, %Ctx{} = ctx) do
    with :ok <- write_answer(answer, ctx), do: {:ok, exit_code(answer)}
  end

  def render({:data, table}, %Ctx{table: true} = ctx) do
    with :ok <- write_text_to_output(Layout.text(nil, table), ctx), do: {:ok, 0}
  end

  def render({:data, table}, %Ctx{} = ctx) do
    with :ok <- write_rows_to_output(table, ctx), do: {:ok, 0}
  end

  defp write_answer(%Answer{table: table}, %Ctx{csv: true} = ctx),
    do: write_rows_to_output(table, ctx)

  defp write_answer(%Answer{table: table}, %Ctx{output: path} = ctx) when is_binary(path),
    do: write_rows_to_output(table, ctx)

  defp write_answer(%Answer{title: title} = answer, ctx),
    do: write_text_to_output(Layout.text(title, shown_table(answer)), ctx)

  defp shown_table(%Answer{shown: nil, table: table}), do: table
  defp shown_table(%Answer{shown: shown}), do: shown

  defp exit_code(%Answer{found: true}), do: 1
  defp exit_code(%Answer{found: false}), do: 0

  defp write_text_to_output(text, %Ctx{output: nil, out: out}), do: IO.write(out, text)

  defp write_text_to_output(text, %Ctx{output: path}),
    do: path |> File.write(text) |> file_written(path)

  defp write_rows_to_output(table, %Ctx{output: nil, out: out, output_opts: pairs}) do
    with {:ok, opts} <- writer_options(Refract.CSV, pairs) do
      table.rows
      |> Refract.CSV.encode(
        [header: table.header] ++ Keyword.put_new(opts, :escape_formulas, false)
      )
      |> Enum.each(&IO.write(out, &1))
    end
  end

  defp write_rows_to_output(table, %Ctx{output: path, output_opts: pairs}) do
    with {:ok, writer} <- find_writer(path),
         {:ok, opts} <- writer_options(writer, pairs) do
      table.rows
      |> writer.write(path, [header: table.header] ++ opts)
      |> file_written(path)
    end
  end

  defp find_writer(path) do
    with {:error, {:unsupported, extension}} <- Refract.Writer.for_path(path, Plugins.writers()),
         do: {:error, handle_no_writer(extension, Plugins.plugin_for(extension))}
  end

  defp handle_no_writer(extension, {:ok, plugin}),
    do: "no writer for .#{extension} files, add one with: refract plugins add #{plugin}"

  defp handle_no_writer(extension, :error), do: "no writer for .#{extension} files"

  defp writer_options(writer, pairs),
    do: Opts.to_options(pairs, writer.encode_options(), writer_name(writer))

  defp writer_name(writer),
    do: "the #{writer |> Module.split() |> List.last() |> String.downcase()} writer"

  defp file_written(:ok, _path), do: :ok

  defp file_written({:error, reason}, path),
    do: {:error, "cannot write #{path}: #{:file.format_error(reason)}"}
end
