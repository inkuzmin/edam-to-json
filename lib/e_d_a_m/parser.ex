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
                                                      id,
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


    File.write(
      "edam.json",
      build_tree("http://www.w3.org/2002/07/owl#Thing", relations, descriptions, %{})
      |> Poison.encode!(pretty: pretty),
      [:binary]
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
