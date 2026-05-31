# read dataset from db
cfg <- yaml::read_yaml("2025/config/db.yml")$default

con <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = cfg$host,
  port = cfg$port,
  dbname = cfg$dbname,
  user = cfg$user
)