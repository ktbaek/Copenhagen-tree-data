-- Create staging tables
create table if not exists raw_genera (
    genus_name text,
    family_name text
);

create table if not exists raw_families (
    family_name text,
    order_name text
);

create table if not exists raw_orders (
    order_name text
);

create table if not exists raw_districts (
    district_name text
);

create table if not exists raw_taxa (
    genus text,
    species_epithet text,
    is_hybrid boolean,
    infraspecies_type text,
    infraspecies_name text,
    taxon_level text
);

create table if not exists raw_taxon_common_names (
    genus text,
    species_epithet text,
    is_hybrid boolean,
    infraspecies_name text,
    infraspecies_type text,
    common_name text
);

create table if not exists raw_trees (
    uuid uuid,
    genus text,
    species_epithet text,
    is_hybrid boolean,
    sex text,
    infraspecies_type text,
    infraspecies_name text,
    planting_year integer,
    district_name text,
    protected text,
    special boolean,
    iconic boolean,
    fruit boolean,
    lon double precision,
    lat double precision,
    is_duplicate_location boolean,
    raw_dansk_navn text,
    raw_slaegtsnavn text
);

create table if not exists raw_taxon_icons (
    genus text,
    species_epithet text,
    is_hybrid boolean,
    infraspecies_type text,
    infraspecies_name text,
    icon_id integer,
    allow_fallback boolean
);