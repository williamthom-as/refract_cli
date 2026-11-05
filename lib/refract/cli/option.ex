defmodule Refract.CLI.Option do
  @moduledoc """
  a command's own option: its parse type, the value it names in help, a line saying what it is,
  and whether it is required
  """

  @enforce_keys [:type, :value, :text]

  defstruct [:type, :value, :text, required: false]

  @type t :: %__MODULE__{
          type: :boolean | :string | :integer | :list,
          value: String.t() | nil,
          text: String.t(),
          required: boolean()
        }
end
