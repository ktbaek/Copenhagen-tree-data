# Cleaning, QC of Copenhagen's municipal tree dataset

## Data source

The dataset from Københavns Kommune was downloaded from [Open Data DK](https://www.opendata.dk/city-of-copenhagen/trae-basis-kommunale-traeer) in September 2025.

## Cleaning steps

1. Check for duplicate UUIDs
2. Check that year of planting is not out of bounds
3. Swap accented letters in the scientific names for accepted latin letters
4. De-capitalize Danish names word multiple words
5. Normalize hybrid markers (e.g. x to hybr.)
6. Normalize cultivar quotes (e.g. " to ')
7. Fix mistakes in scientific names (e.g. spelling, missing species epiphet in cultivars, missing hybrid markers)
8. Fix mistakes in Danish names (e.g. spelling, compound words)
9. Separate scientific names into their components
10. Fix Danish names according to the scientific name (incl special names for cultivars and variants)
11. Fix Danish genus name according to scientific name
12. Flag entries with identical locations


## Online Shiny-app
