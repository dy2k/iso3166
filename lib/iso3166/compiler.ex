defmodule Iso3166.Compiler do
  alias Iso3166.{Country, Subdivision, Geo}

  defmacro __before_compile__(_env) do
    Application.start(:yamerl)

    countries = load_data('countries')
    subdivisions = load_data('subdivisions')
    countries_trans = load_translation('countries')
    languages_trans = load_translation('languages')

    quote do
      def countries do
        unquote(Macro.escape(countries))
      end

      def subdivisions do
        unquote(Macro.escape(subdivisions))
      end

      def translations do
        %{
          countries: unquote(Macro.escape(countries_trans)),
          languages: unquote(Macro.escape(languages_trans))
        }
      end
    end
  end

  defp data_path(path) do
    Path.join('data', path) |> Path.expand(__DIR__)
  end

  defp translation_path(path) do
    Path.join('translation', path) |> Path.expand(__DIR__)
  end

  defp process_data_file(type, file) do
    data_path("#{type}/#{file}.yaml")
    |> :yamerl.decode_file
    |> List.first
    |> case do
      :null -> []
      data -> Enum.reduce(data, %{}, fn({id, result}, records) ->
        case type do
          'countries' -> records = convert_to(result, %Country{})
          'subdivisions' -> Map.put(records, id, convert_to(result, %Subdivision{}))
          _ -> Map.put(records, id, convert_to(result, %{}))
        end
      end)
    end
  end

  defp process_translation_file(type, file) do
    translation_path("#{type}-#{file}.txt")
    |> File.read!
    |> String.split("\n")
    |> Enum.filter_map(&(String.contains?(&1, ";;")), &(&1 |> String.split(";;")))
    |> Enum.reduce(%{}, fn([code, translation], records) ->
      Map.put(records, code |> String.downcase |> String.to_atom, translation) 
    end)
  end

  defp convert_to(result, struct) do
    Enum.reduce(result, struct, fn({key, value}, acc) ->
      Map.put(acc, key |> to_string |> String.to_atom, case key do
                'geo' -> convert_to(value, %Geo{})
                'translations' -> convert_to(value, %{})
                _ -> value |> to_string
              end)
    end)
  end
  
  defp filter_by_config(data, setting) do
    case Application.get_env(:iso3166, setting) do
      list when is_list(list) -> Enum.filter(data, &(Enum.member?(list, &1)))
      _ -> data
    end
  end

  def load_data(type) do
    data_path(type)
    |> File.ls!
    |> Enum.map(&(&1 |> Path.basename('.yaml') |> String.downcase |> String.to_atom))
    |> filter_by_config(:countries)
    |> Enum.reduce(%{}, fn(file, data) -> 
      Map.put(data, file, process_data_file(type, file))
    end)
  end

  def load_translation(type) do
    translation_path("#{type}-*.txt")
    |> Path.wildcard
    |> Enum.map(&(&1 |> Path.basename('.txt') |> String.replace("#{type}-", "") |> String.downcase |> String.to_atom))
    |> filter_by_config(:locales)
    |> Enum.reduce(%{}, fn(file, data) ->
      Map.put(data, file, process_translation_file(type, file))
    end)
  end

end
