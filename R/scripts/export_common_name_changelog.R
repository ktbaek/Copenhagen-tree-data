# connect to db
cfg <- yaml::read_yaml("2025/config/db.yml")$default

con <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = cfg$host,
  port = cfg$port,
  dbname = cfg$dbname,
  user = cfg$user
)

diffs_1 <- as_tibble(DBI::dbGetQuery(con, "
SELECT 
raw_dansk_navn,
common_name,
COUNT(*) AS n 

FROM common_name_diffs 
WHERE common_name IS NOT NULL and common_name <> raw_dansk_navn

GROUP BY raw_dansk_navn, common_name
ORDER BY n DESC
"
))


diffs_2 <- as_tibble(DBI::dbGetQuery(con, "
SELECT 
raw_slaegtsnavn,
common_name as genus_common_name,
COUNT(*) AS n 

FROM common_name_diffs 
WHERE common_name IS NOT NULL and common_name <> raw_slaegtsnavn AND taxon_level = 'genus'

GROUP BY raw_slaegtsnavn, common_name
ORDER BY n DESC
"
))

diffs_1 |> write_csv("2025/output/changelog/common_name_changelog_unique.csv")
diffs_2 |> write_csv("2025/output/changelog/genus_common_name_changelog_unique.csv")
