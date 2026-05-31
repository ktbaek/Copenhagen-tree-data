-- Create staging tables
/*
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

create table if not exists raw_places (
    place_name text,
    district_name text
);
*/

create table if not exists raw_taxa (
    family text,
    genus text,
    species text,
    is_hybrid boolean,
    subsp text,
    var text,
    form text,
    selection text,
    fk text,
    cultivar text,
    taxon_level text,
    show_cultivar_in_display boolean
);

create table if not exists raw_taxon_common_names (
    genus text,
    species text,
    is_hybrid boolean,
    subsp text,
    var text,
    form text,
    selection text,
    fk text,
    cultivar text,
    common_name text
);

create table if not exists raw_trees (
    updated_at date,
    uuid text,
    genus text,
    species text,
    is_hybrid boolean,
    subsp text,
    var text,
    form text,
    selection text,
    fk text,
    cultivar text,
    planting_year integer,
    place_name text,
    space_type text,
    district_name text,
    protected text,
    special boolean,
    iconic boolean,
    fruit boolean,
    lon double precision,
    lat double precision,
    is_duplicate_location boolean,
    dansk_navn text,
    slaegtsnavn text
);

create table if not exists raw_taxon_icons (
    genus text,
    species text,
    is_hybrid boolean,
    subsp text,
    var text,
    form text,
    selection text,
    fk text,
    cultivar text,
    icon_id integer,
    allow_fallback boolean
);