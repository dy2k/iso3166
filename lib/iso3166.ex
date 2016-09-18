defmodule Iso3166 do
  require(Iso3166.Compiler)

  alias Iso3166.{Country, Subdivision}

  @before_compile(Iso3166.Compiler)

  def countries(country) when country == :all do
    Enum.map(countries, fn({_, country}) -> country end)
  end

  @doc """
  ## Example
      iex> Iso3166.countries |> map_size
      1
      iex> Iso3166.countries(:all) |> length
      1
      iex> case Iso3166.countries(:hk) do
      ...>  %Iso3166.Country{name: name} -> name
      ...> end
      "Hong Kong"
  """
  def countries(country) when is_atom(country) do
    countries |> Map.get(country)
  end

  @doc """
  ## Example
      iex> Iso3166.subdivisions |> map_size
      1
      iex> Iso3166.subdivisions(:hk) |> map_size
      18
  """
  def subdivisions(country) when is_atom(country) do
    subdivisions |> Map.get(country)
  end

  def subdivisions(country, subdivision) when subdivision == :all do
    Enum.map(subdivisions(country), fn({_, subdivision}) -> subdivision end)
  end

  @doc """
  ## Example
      iex> Iso3166.subdivisions(:hk, :all) |> length
      18
      iex> case Iso3166.subdivisions(:hk, "17") do
      ...>  %Iso3166.Subdivision{name: name} -> name
      ...> end
      "Southern"
  """
  def subdivisions(country, subdivision) when is_atom(country) do
    subdivisions |> Map.get(country) |> Map.get(subdivision |> to_char_list)
  end

  def translate([%Country{} | _] = countries, locale) when is_atom(locale) do
    lang = translations.countries |> Map.get(locale)
    Enum.map(countries, &(Map.put(&1, :name, lang |> Map.get(&1.alpha2 |> String.downcase |> String.to_atom))))
  end

  @doc """
  ## Example
      iex> case Iso3166.translate(Iso3166.countries(:hk), :zh_hk) do
      ...>  [%Iso3166.Country{name: name}] -> name
      ...> end
      "香港"
  """
  def translate(%{} = struct, locale) when is_atom(locale) do
    translate([struct], locale)
  end

  def translations([%Country{} | _] = countries, locale) when is_atom(locale) do
    Enum.map(countries, &(translations.countries |> Map.get(locale) |> Map.get(&1.alpha2 |> String.downcase |> String.to_atom)))
  end

  def translations([%Subdivision{} | _] = subdivisions, locale) when is_atom(locale) do
    Enum.map(subdivisions, &(Map.get(&1.translations, locale) |> to_string)) 
  end

  @doc """
  ## Example
      iex> Iso3166.translations(Iso3166.countries(:all), :zh_hk)
      ["香港"]
      iex> Iso3166.translations(Iso3166.countries(:hk), :en)
      ["Hong Kong"]
      iex> Iso3166.translations(Iso3166.subdivisions(:hk, :all), :zh) |> length
      18
      iex> Iso3166.translations(Iso3166.subdivisions(:hk, "17"), :en)
      ["Southern"]
  """
  def translations(%{} = struct, locale) when is_atom(locale) do
    translations([struct], locale)
  end

  def find_by(type, field, args) when is_binary(type) and field == "" and is_list(args) do
    case type do
      "country" -> case args do
        [filter, value] when is_atom(filter) -> find_by(type, to_string(filter), [value])
        _ -> raise ArgumentError, message: "for attribute-based finder method"
      end
      "subdivision" -> case args do
        [country, filter, value] when is_atom(filter) -> find_by(type, to_string(filter), [country, value])
        _ -> raise ArgumentError, message: "for attribute-based finder method"
      end
      _ -> raise UndefinedFunctionError, module: __MODULE__, function: "find_" <> type, arity: length(args)
    end
  end

  @doc """
  ## Example
      iex> Iso3166.find_country_by_region("Asia") |> length
      1
      iex> Iso3166.find_country(:region, "Asia") |> length
      1
      iex> Iso3166.find_subdivision_by_name(:hk, "Southern") |> length
      1
      iex> Iso3166.find_subdivision(:hk, :name, "Southern") |> length
      1
  """
  def find_by(type, field, args) when is_binary(type) and is_binary(field) and is_list(args) do
    case type do
      "country" -> case args do
        [value] -> Enum.filter_map(countries, fn({_, country}) -> 
          Map.get(country, field |> String.to_atom) == value end, fn({_, country}) -> country end)
        _ -> raise ArgumentError, message: "for attribute-based finder method"
      end
      "subdivision" -> case args do
        [country, value] -> Enum.filter_map(subdivisions(country), fn({_, subdivision}) ->
          Map.get(subdivision, field |> String.to_atom) == value end, fn({_, subdivision}) -> subdivision end)
        _ -> raise ArgumentError, message: "for attribute-based finder method"
      end
      _ -> raise UndefinedFunctionError, module: __MODULE__, function: "find_" <> type <> "by_" <> field, arity: length(args)
    end
  end

  def list_by(type, field, args) when is_binary(type) and field == "" and is_list(args) do
    case type do
      "country" -> case args do
        [lister] when is_atom(lister) -> list_by(type, to_string(lister), [])
        [lister, filter, value] when is_atom(lister) and is_atom(filter) -> list_by(type, to_string(lister), [filter, value])
        _ -> raise ArgumentError, message: "for attribute-based lister method"
      end
      "subdivision" -> case args do
        [lister, country] when is_atom(lister) and is_atom(country) -> list_by(type, to_string(lister), [country])
        _ -> raise ArgumentError, message: "for attribute-based lister method"
      end
      _ -> raise UndefinedFunctionError, module: __MODULE__, function: "list_" <> type, arity: length(args)
    end
  end

  @doc """
  ## Example
      iex> Iso3166.list_country_by_name
      ["Hong Kong"]
      iex> Iso3166.list_country(:name)
      ["Hong Kong"]
      iex> Iso3166.list_country_by_name(:region, "Asia")
      ["Hong Kong"]
      iex> Iso3166.list_country(:name, :region, "Asia")
      ["Hong Kong"]
      iex> Iso3166.list_subdivision_by_name(:hk) |> length
      18
      iex> Iso3166.list_subdivision(:name, :hk) |> length
      18
  """
  def list_by(type, field, args) when is_binary(type) and is_binary(field) and is_list(args) do
    case type do
      "country" -> case args do
        [] -> Enum.map(countries, fn({_, country}) -> Map.get(country, field |> String.to_atom) end)
        [filter, value] -> Enum.map(find_by(type, to_string(filter), [value]), &(Map.get(&1, field |> String.to_atom)))
        _ -> raise ArgumentError, message: "for attribute-based lister method"
      end
      "subdivision" -> case args do
        [country] -> Enum.map(subdivisions(country), fn({_, subdivision}) -> Map.get(subdivision, field |> String.to_atom) end)
        _ -> raise ArgumentError, message: "for attribute-based lister method"
      end
      _ -> raise UndefinedFunctionError, module: __MODULE__, function: "list_" <> type <> "by_" <> field, arity: length(args)
    end
  end

  def unquote(:"$handle_undefined_function")(command, args) do
    case Regex.named_captures(~r/(?<method>[a-z]+)_(?<type>[a-z]+)(_by_(?<field>[a-z_]+))?/, command |> to_string) do
      %{"method" => "find", "type" => type, "field" => field} -> find_by(type, field, args)
      %{"method" => "list", "type" => type, "field" => field} -> list_by(type, field, args)
      nil -> raise UndefinedFunctionError, module: __MODULE__, function: command, arity: length(args)
    end
  end

end
