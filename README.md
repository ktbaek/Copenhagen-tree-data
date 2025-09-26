# Cleaning, QC of Copenhagen's municipal tree dataset

## Data source

The dataset from Københavns Kommune was downloaded from [Open Data DK](https://www.opendata.dk/city-of-copenhagen/trae-basis-kommunale-traeer) in September 2025. It contains information about ~67,000 trees in Copenhagen.

## Cleaning steps

1. Check for duplicate UUIDs
2. Check that year of planting is within an expected range
3. Swap accented letters in the scientific names for accepted latin letters
4. De-capitalize Danish names with multiple words
5. Normalize hybrid markers (e.g. `x` to `hybr.`)
6. Normalize cultivar quotes (e.g. `"` to `'`)
7. Fix mistakes in scientific names (e.g. spelling, missing species epiphet in cultivars, missing hybrid markers) according to [these rules](rules/latin_rules.csv)
8. Fix mistakes in Danish names (e.g. spelling, compound words) according to [these rules](rules/da_rules.csv)
9. Separate scientific names into their components
10. Fix Danish names based on the scientific name (incl. special names for cultivars and variants) according to [these](rules/latin_da_map.csv) and [these](rules/latin_da_map_malus.csv) rules
11. Fix Danish genus names based on the scientific name according to [these rules](rules/genus_dict.csv)
12. Flag entries with identical locations.

Steps 10 and 11 assume that the scientific names are the ground truth. This is probably true in the vast majority of cases, but without knowing the history of the dataset it can't be known for certain.

The rule sets are not yet complete, but reflect an ongoing effort.

All changes have been recorded in a [changelog](output/). So far, ~17,000 changes (543 unique) have been made to the original dataset.


## Online Shiny-app

I used the cleaned and quality controlled dataset to develop an [interactive map](https://ktbaek.shinyapps.io/treemap_basic/) as a handy tool to explore the trees of Copenhagen!

![App image](app_screenshot.png)
