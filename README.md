# From raw data to structured taxonomy: Copenhagen’s urban tree dataset

In this project I have built a clean, structured, and map-ready dataset of urban trees based on public municipal data from Københavns Kommune. 

The raw data contains several inconsistencies, such as missing or incorrect taxonomy, inconsistent naming, and duplicate records, which makes it difficult to use directly in applications. This repository implements a reproducible pipeline to clean, normalize, and enrich the data, and to prepare it for use in an interactive online map. 

### What the project does

- Cleans and standardizes raw tree data using rule-based transformations in R
- Builds a normalized relational database in PostgreSQL with constraints ensuring integrity
- Resolves taxonomy (genus, species, infraspecies) into a consistent structure
- Derives common names with fallback logic
- Maps taxa to custom-designed taxon-specific icons
- Deduplicates trees with identical coordinates
- Outputs a dataset optimized for use in an interactive map
- Leaves an audit trail of every change made to the raw dataset

### Key design principles

- Scientific name is the ground truth
- All naming logic is anchored in taxonomy
- R handles data cleaning and rule-based transformations
- SQL handles relational structure and derived views
- The entire pipeline from raw data to final map dataset is scripted and reproducible

## Data source

The dataset from Københavns Kommune was downloaded from [Open Data DK](https://www.opendata.dk/city-of-copenhagen/trae-basis-kommunale-traeer) in September 2025. It contains information about ~67,000 trees in Copenhagen. The original dataset is not included here and is licensed under `CC-BY-4.0`.

The contents of this repository (data cleaning code, validation rules, and correction methodologies) are licensed under `AGPL-3.0`.

## Cleaning steps

- Check for duplicate UUIDs
- Flag entries with identical locations
- Check that year of planting is within an expected range
- Normalize hybrid markers (e.g. `x` to `hybr.`)
- Normalize cultivar quotes (e.g. `"` to `'`)
- Fix mistakes in scientific names (e.g. spelling, diacritics, missing species epithet in cultivars, missing hybrid markers) according to [these rules](rules/latin_regex.csv)
- Fix mistakes in Danish names (e.g. spelling, capitalization, compound words) according to [these rules](rules/danish_regex.csv)
- Separate scientific names into their logical components
- Fix Danish names based on the scientific name (incl. special Danish names for cultivars and variants) according to [these](rules/latin_da_map.csv) and [these](rules/latin_da_map_malus.csv) rules
- Fix Danish genus names based on the scientific name according to [these rules](rules/genus_dict.csv)


The last two steps assume that the scientific names are the ground truth. This is probably true in the vast majority of cases, but without knowing the history of the dataset it can't be known for certain.

The rule sets are not complete, but reflect an ongoing effort.

Approximately 20,000 changes (appr. 570 unique) have been applied to the dataset. Some corrections are counted more than once when multiple rules act in sequence, for example, “Park-Lind” → “Park-lind” → “Parklind.” All changes are listed in the [changelog](output/).


## Interactive map

I used the cleaned and quality controlled dataset to develop a beautiful and user-friendly [interactive map](https://cphtreemap.netlify.app#map) using the Leaflet JavaScript library. The map is a handy tool for exploring the trees of Copenhagen.

![App image](map-sshot.png)

## Attribution

If you use, modify, or build upon the data cleaning methodologies and code in this repository, please include the following attribution:

```
Data cleaning methodology: Kristoffer T. Bæk (2020-2025)
https://github.com/ktbaek/Copenhagen-tree-data
Licensed under AGPL-3.0

Original tree data: © Københavns Kommune
https://www.opendata.dk/city-of-copenhagen/trae-basis-kommunale-traeer
Licensed under CC-BY-4.0
```