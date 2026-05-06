## Updating species descriptions

1. **Aggregate species data** from the updated dataset using `make_species_json.R` in R. 
2. **Identify differences to old aggregated data** with `make_species_diff.R`.
3. **Update descriptions with Claude API** with `update_descriptions.py`.
4. **Generate descriptsions for new species** with `generate_descriptions.py` using a json with only the species stats for the new species.   
5. **Merge descriptions** from updated descriptions with descriptions from new species into one json (copy/paste). 
6. **Make manual edits** if needed. 
6. **Upsert into database** with `descriptions_json_to_db.R`in R. 
7. **Export back to json** with `descriptions_db_to_json.R`in R if needed.