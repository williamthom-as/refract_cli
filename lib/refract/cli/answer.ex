defmodule Refract.CLI.Answer do
  @moduledoc """
  An answer is the result of what a commmand request found, used to give commands the direct
  control at invokation to determine what the result presents.

  the table is what --csv writes, shown is what is displayed on screen, and found is used for
  return codes (exit 1 or 0).
  """

  @enforce_keys [:table]

  defstruct [:title, :table, :shown, found: false]

  @type t :: %__MODULE__{
          title: String.t() | nil,
          table: Refract.Table.t(),
          shown: Refract.Table.t() | nil,
          found: boolean()
        }
end
