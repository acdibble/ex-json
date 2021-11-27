defmodule Json do
  def parse(string), do: parse_value(string, "", 0) |> finish()

  defp finish({:ok, value, " " <> tail, position}), do: finish({:ok, value, tail, position + 1})
  defp finish({:ok, value, "\n" <> tail, position}), do: finish({:ok, value, tail, position + 1})
  defp finish({:ok, value, "\r" <> tail, position}), do: finish({:ok, value, tail, position + 1})
  defp finish({:ok, value, "\t" <> tail, position}), do: finish({:ok, value, tail, position + 1})
  defp finish({:ok, "", "", 0}), do: {:err, :empty}
  defp finish({:ok, value, "", _position}), do: {:ok, value}
  defp finish({_, <<ch::utf8>> <> _rest, pos}), do: {:err, pos, <<ch>>}
  defp finish({:err, "", _position}), do: {:err, :unexpected_end_of_input}
  defp finish({_, _value, <<ch::utf8>> <> _rest, pos}), do: {:err, pos, <<ch>>}

  defp parse_value(" " <> tail, "", position), do: parse_value(tail, "", position + 1)
  defp parse_value("\t" <> tail, "", position), do: parse_value(tail, "", position + 1)
  defp parse_value("\n" <> tail, "", position), do: parse_value(tail, "", position + 1)
  defp parse_value("\r" <> tail, "", position), do: parse_value(tail, "", position + 1)

  defp parse_value("n" <> tail, "", position), do: parse_value(tail, "n", position + 1)
  defp parse_value("u" <> tail, "n", position), do: parse_value(tail, "nu", position + 1)
  defp parse_value("l" <> tail, "nu", position), do: parse_value(tail, "nul", position + 1)
  defp parse_value("l" <> tail, "nul", position), do: {:ok, nil, tail, position + 1}

  defp parse_value("t" <> tail, "", position), do: parse_value(tail, "t", position + 1)
  defp parse_value("r" <> tail, "t", position), do: parse_value(tail, "tr", position + 1)
  defp parse_value("u" <> tail, "tr", position), do: parse_value(tail, "tru", position + 1)
  defp parse_value("e" <> tail, "tru", position), do: {:ok, true, tail, position + 1}

  defp parse_value("f" <> tail, "", position), do: parse_value(tail, "f", position + 1)
  defp parse_value("a" <> tail, "f", position), do: parse_value(tail, "fa", position + 1)
  defp parse_value("l" <> tail, "fa", position), do: parse_value(tail, "fal", position + 1)
  defp parse_value("s" <> tail, "fal", position), do: parse_value(tail, "fals", position + 1)
  defp parse_value("e" <> tail, "fals", position), do: {:ok, false, tail, position + 1}

  defp parse_value("[" <> tail, "", position), do: parse_array([], tail, position + 1, :start)

  defp parse_value("{" <> tail, "", position), do: parse_object(%{}, tail, position + 1, nil)

  defp parse_value("0." <> rest, "", position), do: parse_number(rest, "0.", position + 2, :float)

  defp parse_value("-0." <> rest, "", position),
    do: parse_number(rest, "-0.", position + 3, :float)

  defp parse_value("0" <> rest, "", position), do: {:ok, 0, rest, position + 1}
  defp parse_value("-0" <> rest, "", position), do: {:ok, -0, rest, position + 2}

  defp parse_value(<<ch>> <> rest, "", position) when ch in ?1..?9 or ch == ?-,
    do: parse_number(rest, <<ch>>, position + 1, :integer)

  defp parse_value("\"" <> tail, "", position), do: parse_string(tail, "", position + 1)

  defp parse_value("", acc, position), do: {:ok, acc, "", position}

  defp parse_value(rest, _acc, position), do: {:err, rest, position}

  defp parse_string("\\\"" <> tail, acc, position),
    do: parse_string(tail, acc <> "\"", position + 2)

  defp parse_string("\\u" <> tail, acc, position),
    do: parse_unicode(tail, acc, position + 2, "", 0)

  defp parse_string("\\\n" <> tail, acc, position),
    do: parse_string(tail, acc <> "\n", position + 2)

  defp parse_string("\\\\" <> tail, acc, position),
    do: parse_string(tail, acc <> "\\", position + 2)

  defp parse_string("\"" <> tail, acc, position),
    do: {:ok, acc, tail, position + 1}

  defp parse_string(<<ch::utf8>> <> tail, acc, position),
    do: parse_string(tail, acc <> <<ch>>, position + 1)

  defp parse_string("", _acc, position), do: {:err, "", position}

  defp parse_unicode(tail, acc, position, hex, 4),
    do: parse_string(tail, acc <> <<String.to_integer(hex, 16)>>, position)

  defp parse_unicode(<<ch::utf8>> <> tail, acc, position, hex, length),
    do: parse_unicode(tail, acc, position + 1, hex <> <<ch>>, length + 1)

  defp parse_number(<<ch::utf8>> <> rest, acc, position, type) when ch in ?0..?9,
    do: parse_number(rest, acc <> <<ch>>, position + 1, type)

  defp parse_number("." <> <<ch>> <> rest, acc, position, :integer) when ch in ?0..?9,
    do: parse_number(rest, acc <> "." <> <<ch>>, position + 2, :float)

  defp parse_number("." <> _rest, _acc, position, :float), do: {:err, ".", position}
  defp parse_number("." <> rest, _acc, position, _type), do: {:err, rest, position + 1}

  defp parse_number("e" <> rest, acc, position, :float) do
    {rest, pow, position} = parse_pow(rest, "", position)
    {:ok, Float.pow(String.to_float(acc), pow), rest, position}
  end

  defp parse_number("e" <> rest, acc, position, :integer) do
    {rest, pow, position} = parse_pow(rest, "", position)
    {:ok, Integer.pow(String.to_integer(acc), pow), rest, position}
  end

  defp parse_number(rest, acc, position, :integer),
    do: {:ok, String.to_integer(acc), rest, position}

  defp parse_number(rest, acc, position, :float), do: {:ok, String.to_float(acc), rest, position}

  defp parse_pow(<<ch::utf8>> <> rest, acc, position) when ch in ?0..?9,
    do: parse_pow(rest, acc <> <<ch>>, position + 1)

  defp parse_pow(rest, acc, position), do: {rest, String.to_integer(acc), position}

  defp parse_array(_list, "", position, _prev), do: {:err, "", position}

  defp parse_array(list, " " <> tail, position, prev),
    do: parse_array(list, tail, position + 1, prev)

  defp parse_array(list, "\n" <> tail, position, prev),
    do: parse_array(list, tail, position + 1, prev)

  defp parse_array(list, "\t" <> tail, position, prev),
    do: parse_array(list, tail, position + 1, prev)

  defp parse_array(list, "\r" <> tail, position, prev),
    do: parse_array(list, tail, position + 1, prev)

  defp parse_array(list, "," <> tail, position, _prev),
    do: parse_array(list, tail, position + 1, :comma)

  defp parse_array(_list, "]" <> tail, position, :comma),
    do: {:err, "]" <> tail, position}

  defp parse_array(list, "]" <> tail, position, _prev),
    do: {:ok, Enum.reverse(list), tail, position + 1}

  defp parse_array(list, string, position, _prev),
    do: prepend_element(list, parse_value(string, "", position))

  defp prepend_element(list, {:ok, value, rest, new_position}),
    do: parse_array([value | list], rest, new_position, :element)

  defp prepend_element(_list, err), do: err

  defp parse_object(_map, "", position, _key), do: {:err, "", position}
  defp parse_object(map, "}" <> tail, position, nil), do: {:ok, map, tail, position + 1}

  defp parse_object(map, "," <> tail, position, nil),
    do: parse_object(map, tail, position + 1, nil)

  defp parse_object(map, " " <> tail, position, key),
    do: parse_object(map, tail, position + 1, key)

  defp parse_object(map, "\r" <> tail, position, key),
    do: parse_object(map, tail, position + 1, key)

  defp parse_object(map, "\n" <> tail, position, key),
    do: parse_object(map, tail, position + 1, key)

  defp parse_object(map, "\t" <> tail, position, key),
    do: parse_object(map, tail, position + 1, key)

  defp parse_object(map, ":" <> tail, position, key) when is_binary(key),
    do: parse_object(map, tail, position + 1, key)

  defp parse_object(map, "\"" <> tail, position, nil),
    do: parse_key(map, parse_string(tail, "", position + 1))

  defp parse_object(map, string, position, key) when is_binary(key),
    do: set_value_in_map(map, key, parse_value(string, "", position))

  defp set_value_in_map(map, key, {:ok, value, tail, position}),
    do: Map.put(map, key, value) |> parse_object(tail, position, nil)

  defp parse_key(map, {:ok, key, tail, position}), do: parse_object(map, tail, position, key)
  defp parse_key(_map, err), do: err

  def stringify(nil), do: "null"
  def stringify(true), do: "true"
  def stringify(false), do: "false"

  def stringify(value) when is_binary(value), do: "\"" <> value <> "\""

  def stringify([]), do: "[]"
  def stringify(value) when is_list(value), do: stringify_list("[", value)

  def stringify(value) when is_map(value), do: stringify_map("{", Map.to_list(value))

  def stringify(value) when is_tuple(value), do: Tuple.to_list(value) |> stringify()

  def stringify(value) when is_atom(value), do: to_string(value) |> stringify()
  def stringify(value), do: to_string(value)

  defp stringify_list(acc, [head | []]), do: acc <> stringify(head) <> "]"

  defp stringify_list(acc, [head | tail]),
    do: (acc <> stringify(head) <> ",") |> stringify_list(tail)

  defp stringify_map(acc, [{key, value} | []]),
    do: acc <> stringify_map_key(key) <> ":" <> stringify(value) <> "}"

  defp stringify_map(acc, [{key, value} | tail]),
    do:
      (acc <> stringify_map_key(key) <> ":" <> stringify(value) <> ",")
      |> stringify_map(tail)

  defp stringify_map(acc, []), do: acc <> "}"

  defp stringify_map_key(key) when is_binary(key), do: stringify(key)
  defp stringify_map_key(key), do: "\"" <> stringify(key) <> "\""
end
