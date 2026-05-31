CREATE OR REPLACE VIEW rarity AS
with rare_taxa AS (

    select
    		tx.genus_id,
        tx.species_taxon_id,
  		CASE
            WHEN COUNT(t.*) = 1 THEN 1
            WHEN COUNT(t.*) BETWEEN 2 AND 5 THEN 2
            WHEN COUNT(t.*) BETWEEN 6 AND 10 THEN 3
            ELSE NULL
        END AS rarity

    FROM trees t
    LEFT JOIN taxa tx
		ON t.taxon_id = tx.taxon_id
    GROUP BY 1, 2

)


select
	tx.taxon_id,
	rt.rarity
	
FROM taxa tx
left join rare_taxa rt on rt.species_taxon_id is not distinct from tx.species_taxon_id 
and rt.genus_id is not distinct from tx.genus_taxon_id
where rt.rarity is not null
order by tx.taxon_id;