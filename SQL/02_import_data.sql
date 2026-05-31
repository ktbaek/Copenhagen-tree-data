begin;
truncate tree_place_import;
\copy tree_place_import from 'output/tables/uuid_place_type.csv' delimiter ',' csv header;
commit;