-- table orders
create table if not exists orders (
    order_id serial primary key, 
    order_name text not null unique
);

-- table families
create table if not exists families (
    family_id serial primary key,
    family_name text not null unique,
    order_id integer not null references orders(order_id)
);

-- table genera
create table if not exists genera (
    genus_id serial primary key,
    genus_name text not null unique,
    family_id integer not null references families(family_id),
    taxon_id integer
);

-- table districts
create table if not exists districts (
    district_id serial primary key,
    district_name text not null unique
);

-- table taxa
create table if not exists taxa (
    taxon_id serial primary key,
    genus_id integer not null references genera(genus_id),
    species_taxon_id INTEGER,
    species_epithet TEXT,
    is_hybrid BOOLEAN NOT NULL DEFAULT FALSE,
    infraspecies_name TEXT,
    infraspecies_type TEXT CHECK (
        infraspecies_type is null or
        infraspecies_type IN ('cultivar', 'var.', 'ssp.', 'f.', 'fk', 'sel.')
    ),
    taxon_level TEXT NOT NULL CHECK (
        taxon_level IN ('genus', 'species', 'infraspecies')
    ),
    show_cultivar_in_display BOOLEAN DEFAULT FALSE,

    -- prevent empty strings
    CHECK (species_epithet IS NULL OR species_epithet <> ''),
    CHECK (infraspecies_name IS NULL OR infraspecies_name <> ''),

    -- prevent NULLs for species/intraspecies
    CHECK (species_taxon_id IS NOT NULL OR taxon_level = 'genus'),

    -- enforce structure
    CONSTRAINT valid_structure CHECK (

        -- GENUS
        (taxon_level = 'genus'
            AND species_epithet IS NULL
            AND infraspecies_name IS NULL
            AND is_hybrid = FALSE)

        OR

        -- SPECIES (normal)
        (taxon_level = 'species'
            AND species_epithet IS NOT NULL
            AND infraspecies_name IS NULL)

        OR

        -- HYBRID SPECIES WITHOUT EPITHET
        (taxon_level = 'species'
            AND species_epithet IS NULL
            AND infraspecies_name IS NULL
            AND is_hybrid = TRUE)

        OR

        -- INFRASPECIES (normal)
        (taxon_level = 'infraspecies'
            AND species_epithet IS NOT NULL
            AND infraspecies_name IS NOT NULL)

        OR

        -- HYBRID INFRASPECIES WITHOUT SPECIES
        (taxon_level = 'infraspecies'
            AND species_epithet IS NULL
            AND infraspecies_name IS NOT NULL
            AND is_hybrid = TRUE)
    ),

    -- type only for infraspecies
    CONSTRAINT valid_type_usage CHECK (
        (taxon_level = 'infraspecies' AND infraspecies_type IS NOT NULL)
        OR
        (taxon_level != 'infraspecies' AND infraspecies_type IS NULL)
    )
);

CREATE UNIQUE INDEX unique_taxa_natural
ON taxa (
    genus_id,
    COALESCE(species_epithet, ''),
    COALESCE(infraspecies_name, ''),
    COALESCE(infraspecies_type, ''),
    is_hybrid
);

ALTER TABLE taxa
ADD CONSTRAINT fk_species_taxon
FOREIGN KEY (species_taxon_id)
REFERENCES taxa(taxon_id);

-- add fk to genera
ALTER TABLE genera
ADD CONSTRAINT fk_genus_taxon
FOREIGN KEY (taxon_id)
REFERENCES taxa(taxon_id);

ADD CONSTRAINT unique_genus_taxon UNIQUE (taxon_id);

-- table taxon_common_names
create table if not exists taxon_common_names (
    common_name_id serial primary key,
    taxon_id integer not null references taxa(taxon_id) ON DELETE CASCADE,
    common_name TEXT NOT NULL,

    -- avoid duplicates per taxon
    UNIQUE (taxon_id, common_name),

    -- basic sanity
    CHECK (common_name <> '')
);

-- table trees
create table if not exists trees (
    updated_at date,
    uuid uuid primary key,
    taxon_id integer references taxa(taxon_id),
    sex text check (
        sex is null or
        sex in ('male', 'female', 'han', 'hun')),
    lat double precision not null,
    lon double precision not null,
    district_id integer references districts(district_id),
    planting_year integer,
    protected text,
    special boolean not null default false,
    iconic boolean not null default false,
    fruit boolean,
    is_duplicate_location boolean not null default false,
    raw_dansk_navn text,
    raw_slaegtsnavn text
);

-- table taxon_icons
create table if not exists taxon_icons (
    id serial primary key,
    taxon_id INTEGER NOT NULL REFERENCES taxa(taxon_id),
    icon_id integer,
    allow_fallback boolean not null default TRUE
);

-- table taxon_descriptions
CREATE TABLE if not exists taxon_descriptions (
    taxon_id INTEGER PRIMARY KEY REFERENCES taxa(taxon_id),
    prose_html TEXT,
    source TEXT, -- e.g. 'LLM', 'manual'
    created_at DATE,
    updated_at TIMESTAMP
);

