"""
Update species descriptions in species_descriptions.json based on diff_changes.json.
Handles tier_1 (surgical edits) and tier_2 (informed rewrites) separately.
"""

import json
import time
from pathlib import Path
import anthropic
from dotenv import load_dotenv

# Load API key from .env file
load_dotenv()

# ── Config ────────────────────────────────────────────────────────────────────

SPECIES_JSON  = Path("species_descriptions.json")
DIFF_JSON     = Path("diff_changes.json")
OUTPUT_JSON   = Path("species_descriptions_updated.json")
SYSTEM_PROMPT = Path("system_prompt_updates.txt")

PAUSE_BETWEEN_CALLS = 1.0   # seconds, adjust to stay within rate limits
MODEL = "claude-sonnet-4-6"
MAX_TOKENS = 1000

# ── Prompts ───────────────────────────────────────────────────────────────────

def build_tier1_prompt(existing_prose, tier1_changes):
    changes_json = json.dumps(tier1_changes, ensure_ascii=False, indent=2)
    return f"""Du redigerer en dansk artsbeskrivelse til et trækort over København.

Opdater KUN de specifikke værdier angivet i <changes>. Ændr ikke formuleringer, 
struktur eller konklusioner. Hvis en værdi ikke optræder eksplicit i teksten, 
lad teksten være præcis som den er.

Returner kun den opdaterede beskrivelsestekst uden forklaring.

<description>
{existing_prose}
</description>

<changes>
{changes_json}
</changes>"""


def build_tier2_prompt(existing_prose, tier1_changes, tier2_changes):
    tier1_json = json.dumps(tier1_changes, ensure_ascii=False, indent=2)
    tier2_json = json.dumps(tier2_changes, ensure_ascii=False, indent=2)
    return f"""Du redigerer en dansk artsbeskrivelse til et trækort over København.

De underliggende data er opdateret. Følg disse regler:

- Det første afsnit om artens generelle karakteristika skal forblive uændret
- Omskriv kun de følgende afsnit om artens forekomst i København
- Bevar samme længde, tone og struktur som originalen
- Brug data_to som kilde til opdaterede tal og konklusioner
- meaningful_changes fremhæver de ændringer der sandsynligvis påvirker konklusionerne

Hvis allInProminentPlace er ændret:
- Fra null til en værdi: erstat bydelsbaseret beskrivelse med stednavnet
  - count == 1: "det eneste registrerede eksemplar står i [allInProminentPlace]"
  - count == 2: "begge træer står i [allInProminentPlace]"
  - count > 2: "alle [count] træer står i [allInProminentPlace]"
- Fra en værdi til null: arten er ikke længere koncentreret ét sted — 
  beskriv udbredelsen med bydelsdata fra data_to i stedet

Returner kun den fulde opdaterede beskrivelsestekst uden forklaring.

<description>
{existing_prose}
</description>

<tier1_changes>
{tier1_json}
</tier1_changes>

<tier2_changes>
{tier2_json}
</tier2_changes>"""


# ── API call ──────────────────────────────────────────────────────────────────

with SYSTEM_PROMPT.open(encoding="utf-8") as f:
    system_prompt = f.read()

def call_api(client, prompt):
    message = client.messages.create(
        model=MODEL,
        max_tokens=MAX_TOKENS,
        system=system_prompt,
        messages=[{"role": "user", "content": prompt}]
    )
    return message.content[0].text


# ── Main ──────────────────────────────────────────────────────────────────────

def main():

    client = anthropic.Anthropic()

    with SPECIES_JSON.open(encoding="utf-8") as f:
        species_data = json.load(f)

    with DIFF_JSON.open(encoding="utf-8") as f:
        diff_data = json.load(f)
    
    # TEST: remove or comment out when running the full batch
    # diff_data = {k: diff_data[k] for k in ["Acer campestre", "Acer pseudoplatanus"]}

    updated  = 0
    skipped  = 0
    errors   = []

    for species_name, diff_entry in diff_data.items():

        # Get existing prose
        if species_name not in species_data:
            print(f"  SKIP (not in species-info.json): {species_name}")
            skipped += 1
            continue

        existing_prose = species_data[species_name].get("prose", "")
        if not existing_prose:
            print(f"  SKIP (no prose): {species_name}")
            skipped += 1
            continue

        tier          = diff_entry.get("update_tier")
        tier1_changes = diff_entry.get("tier1_changes", [])
        tier2_changes = diff_entry.get("tier2_changes", {})

        try:
            if tier == "tier_2":
                prompt = build_tier2_prompt(existing_prose, tier1_changes, tier2_changes)
            else:
                prompt = build_tier1_prompt(existing_prose, tier1_changes)
        except Exception as e:
            print(f"  ERROR building prompt ({species_name}): {e}")
            continue

        try:
            print(f"  [{tier}] {species_name}")
            new_prose = call_api(client, prompt)
            species_data[species_name]["prose"] = new_prose
            updated += 1
        except Exception as e:
            print(f"  ERROR calling API ({species_name}): {e}")
            errors.append({"species": species_name, "error": str(e)})

        time.sleep(PAUSE_BETWEEN_CALLS)

    # Write output
    with OUTPUT_JSON.open("w", encoding="utf-8") as f:
        json.dump(species_data, f, ensure_ascii=False, indent=2)

    print(f"\nDone.")
    print(f"  Updated: {updated}")
    print(f"  Skipped: {skipped}")
    print(f"  Errors:  {len(errors)}")
    print(f"  Output:  {OUTPUT_JSON}")

    if errors:
        print("\nFailed species:")
        for e in errors:
            print(f"  {e['species']}: {e['error']}")


if __name__ == "__main__":
    main()