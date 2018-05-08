defmodule EDAM.Parser do
  @moduledoc false

  @filename "./data/EDAM_1.20.csv"

  def parse(filename \\ @filename, pretty \\ false) do
    {relations, descriptions} = File.stream!(filename)
                                |> CSV.decode
                                |> Stream.drop(1)
                                |> Enum.reduce(
                                     {%{}, %{}},
                                     fn ({:ok, row}, {accRelations, accDescriptions}) ->
                                       case Enum.at(row, 4) do
                                         "FALSE" ->
                                           Enum.at(row, 7)
                                           |> String.split("|")
                                           |> Enum.reduce(
                                                {accRelations, accDescriptions},
                                                fn (id, {accRelations, accDescriptions}) ->
                                                  {
                                                    Map.update(
                                                      accRelations,
                                                      id,
                                                      [Enum.at(row, 0)],
                                                      fn (value) -> [Enum.at(row, 0) | value] end
                                                    ),
                                                    Map.put(
                                                      accDescriptions,
                                                      Enum.at(row, 0),
                                                      %{
                                                        :label => Enum.at(row, 1),
                                                        :synonyms => if (String.length(Enum.at(row, 2)) > 0) do
                                                          String.split(Enum.at(row, 2), "|")
                                                        else
                                                          nil
                                                        end,
                                                        :description => Enum.at(row, 3)
                                                      }
                                                    )
                                                  }
                                                end
                                              )
                                         _ ->
                                           {accRelations, accDescriptions}
                                       end
                                     end
                                   )

    hierarchy = build_hierarchy("http://www.w3.org/2002/07/owl#Thing", relations, %{})

    #    h |> Map.get("http://www.w3.org/2002/07/owl#Thing") |> Enum.at(0) # deprecated

    [topic_root] = hierarchy
                   |> Map.get("http://www.w3.org/2002/07/owl#Thing")
                   |> Enum.at(1)
                   |> Map.keys
    topic = hierarchy
            |> Map.get("http://www.w3.org/2002/07/owl#Thing")
            |> Enum.at(1)
            |> trim_to_ids(topic_root, %{}, &extract_topic_id/1)


    [operation_root] = hierarchy
                       |> Map.get("http://www.w3.org/2002/07/owl#Thing")
                       |> Enum.at(2)
                       |> Map.keys
    operation = hierarchy
                |> Map.get("http://www.w3.org/2002/07/owl#Thing")
                |> Enum.at(2)
                |> trim_to_ids(operation_root, %{}, &extract_operation_id/1)


    [format_root] = hierarchy
                    |> Map.get("http://www.w3.org/2002/07/owl#Thing")
                    |> Enum.at(3)
                    |> Map.keys
    format = hierarchy
             |> Map.get("http://www.w3.org/2002/07/owl#Thing")
             |> Enum.at(3)
             |> trim_to_ids(format_root, %{}, &extract_format_id/1)

    [data_root] = hierarchy
                  |> Map.get("http://www.w3.org/2002/07/owl#Thing")
                  |> Enum.at(4)
                  |> Map.keys
    data = hierarchy
           |> Map.get("http://www.w3.org/2002/07/owl#Thing")
           |> Enum.at(4)
           |> trim_to_ids(data_root, %{}, &extract_data_id/1)


    h = %{
      :topic => topic,
      :operation => operation,
      :format => format,
      :data => data
    }
    #    build_tree("http://www.w3.org/2002/07/owl#Thing", relations, descriptions, %{})

    File.write(
      "edam-hierarchy.json",
      h
      |> Poison.encode!(pretty: pretty),
      [:binary]
    )

    File.write(
      "edam-search-data.json",
      Enum.filter(descriptions, fn({k, v}) -> Regex.match?(~r{http://edamontology.org/data_}, k) end) |> to_hash
      |> Poison.encode!(pretty: pretty),
      [:binary]
    )

    File.write(
      "edam-search-operation.json",
      Enum.filter(descriptions, fn({k, v}) -> Regex.match?(~r{http://edamontology.org/operation_}, k) end) |> to_hash
      |> Poison.encode!(pretty: pretty),
      [:binary]
    )

    File.write(
      "edam-search-topic.json",
      Enum.filter(descriptions, fn({k, v}) -> Regex.match?(~r{http://edamontology.org/topic_}, k) end) |> to_hash
      |> Poison.encode!(pretty: pretty),
      [:binary]
    )

    File.write(
      "edam-search-format.json",
      Enum.filter(descriptions, fn({k, v}) -> Regex.match?(~r{http://edamontology.org/format_}, k) end) |> to_hash
      |> Poison.encode!(pretty: pretty),
      [:binary]
    )
  end


  def to_hash(struct) do
    Enum.map(struct, fn({k, v}) ->
      %{k => v}
    end)
  end

  def trim_to_ids(tree, node, acc, fun) do
    Map.put(
      acc,
      fun.(node),
      case Map.get(tree, node) do
        nil -> nil
        children ->
          Enum.map(
            children,
            fn (child) ->
              [root] = child
                       |> Map.keys
              trim_to_ids(child, root, %{}, fun)
            end
          )
      end
    )
  end

  def extract_topic_id(nil) do
    nil
  end

  def extract_topic_id(s) do
    [[_, id]] = ~r{http://edamontology.org/topic_(\d*)}
                |> Regex.scan(s)
    id
    |> String.to_integer
  end

  def extract_format_id(nil) do
    nil
  end

  def extract_format_id(s) do
    [[_, id]] = ~r{http://edamontology.org/format_(\d*)}
                |> Regex.scan(s)
    id
    |> String.to_integer
  end

  def extract_operation_id(nil) do
    nil
  end

  def extract_operation_id(s) do
    [[_, id]] = ~r{http://edamontology.org/operation_(\d*)}
                |> Regex.scan(s)
    id
    |> String.to_integer
  end

  def extract_data_id(nil) do
    nil
  end

  def extract_data_id(s) do
    [[_, id]] = ~r{http://edamontology.org/data_(\d*)}
                |> Regex.scan(s)
    id
    |> String.to_integer
  end


  def build_hierarchy(parent, relations, acc) do
    empty_map = %{}
    Map.put(
      acc,
      parent,
      case Map.get(relations, parent) do
        nil -> nil
        children ->
          Enum.map(
            children,
            fn (child) ->
              build_hierarchy(child, relations, %{})
            end
          )
      end
    )
  end

  def build_tree(parent, relations, descriptions, acc) do
    empty_map = %{}
    Map.put(
      acc,
      parent,
      case Map.merge(
             case Map.get(relations, parent) do
               nil -> %{}
               children ->
                 %{
                   :children =>
                     Enum.map(
                       children,
                       fn (child) ->
                         build_tree(child, relations, descriptions, %{})
                       end
                     )
                 }
             end,
             case Map.get(descriptions, parent) do
               nil -> %{}
               x -> x
             end
           ) do
        ^empty_map -> nil
        x -> x
      end
    )

  end



end
