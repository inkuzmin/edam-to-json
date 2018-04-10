# Tool to convert [EDAM.csv](https://github.com/edamontology/edamontology) to hierarchical EDAM.json

## Download the results
Please, check `data/edam.formatted.json`, `data/edam.json`

## Build the results

### [Install Elixir](https://elixir-lang.org/install.html)

### In the directory with `mix.exs`:
```
$ mix deps.get # install dependencies
$ iex -S mix # start REPL
```

### In the REPL:
```
iex(1)> EDAM.Parser.parse("./data/EDAM_1.20.csv", true) # to create pretty formatted edam.json
iex(1)> EDAM.Parser.parse() # to create raw edam.json

```

## EDAM

Files `data/EDAM_1.20.csv` and `data/EDAM_1.20.owl` were downloaded from the latest release of [EDAM](https://github.com/edamontology/edamontology).

Ison, J., Kalaš, M., Jonassen, I., Bolser, D., Uludag, M., McWilliam, H., Malone, J., Lopez, R., Pettifer, S. and Rice, P. (2013). [EDAM: an ontology of bioinformatics operations, types of data and identifiers, topics and formats](http://bioinformatics.oxfordjournals.org/content/29/10/1325.full). _Bioinformatics_, **29**(10): 1325-1332.
[![10.1093/bioinformatics/btt113](https://zenodo.org/badge/DOI/10.1093/bioinformatics/btt113.svg)](https://doi.org/10.1093/bioinformatics/btt113) PMID: [23479348](http://www.ncbi.nlm.nih.gov/pubmed/23479348) _Open Access_

EDAM releases are citable with DOIs too, for cases when that is needed. [![10.5281/zenodo.822690](https://zenodo.org/badge/DOI/10.5281/zenodo.822690.svg)](https://doi.org/10.5281/zenodo.822690) represents all releases and resolves to the DOI of the last stable release. For the DOI of a particular EDAM release, please see [/releases](https://github.com/edamontology/edamontology/tree/master/releases).
