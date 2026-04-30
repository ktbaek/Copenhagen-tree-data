begin;
truncate raw_orders;
\copy raw_orders from 'output/tables/orders.csv' delimiter ',' csv header;
commit;

begin;
truncate raw_families;
\copy raw_families from 'output/tables/families.csv' delimiter ',' csv header;
commit;

begin;
truncate raw_genera;
\copy raw_genera from 'output/tables/genera.csv' delimiter ',' csv header;
commit;

begin;
truncate raw_districts;
\copy raw_districts from 'output/tables/districts.csv' delimiter ',' csv header;
commit;

begin;
truncate raw_taxa;
\copy raw_taxa from 'output/tables/taxa.csv' delimiter ',' csv header;
commit;

begin;
truncate raw_taxon_common_names;
\copy raw_taxon_common_names from 'output/tables/taxon_common_names.csv' delimiter ',' csv header;
commit;

begin;
truncate raw_taxon_icons;
\copy raw_taxon_icons from 'output/tables/icons.csv' delimiter ',' csv header;
commit;

begin;
truncate raw_trees_2026;
\copy raw_trees_2026 from 'output/tables/trees_2026.csv' delimiter ',' csv header;
commit;