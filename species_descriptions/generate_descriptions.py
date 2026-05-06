import anthropic
import json
import time
from dotenv import load_dotenv

# Load API key from .env file
load_dotenv()

# Initialize client (automatically uses ANTHROPIC_API_KEY)
client = anthropic.Anthropic()

# Load system prompt
with open("system_prompt.txt", encoding="utf-8") as f:
    system_prompt = f.read()

# Load species data
with open("new_species_data_2026.json", encoding="utf-8") as f:
    species = json.load(f)

descriptions = {}

for i, (latin_name, data) in enumerate(species.items()):
    data["latinName"] = latin_name
    
    user_prompt = f"Skriv en artsbeskrivelse baseret på følgende data:\n\n{json.dumps(data, ensure_ascii=False)}"
    
    response = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1024,
        system=system_prompt,
        messages=[{"role": "user", "content": user_prompt}]
    )
    
    descriptions[latin_name] = {"prose": response.content[0].text}
    
    print(f"{i+1}/{len(species)}: {latin_name}")
    time.sleep(0.5)

with open("species_descriptions_new.json", "w", encoding="utf-8") as f:
    json.dump(descriptions, f, ensure_ascii=False, indent=2)

print("Done!")