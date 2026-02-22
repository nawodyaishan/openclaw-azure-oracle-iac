import re
import os

files_to_fix = [
    'infra/oracle/main.tf',
    'infra/oracle/outputs.tf',
    'infra/azure/main.tf',
    'infra/azure/outputs.tf'
]

for fp in files_to_fix:
    if not os.path.exists(fp):
        continue
    with open(fp, 'r') as f:
        text = f.read()
    
    # Standardize singleton names
    text = text.replace(' "main" {', ' "this" {')
    text = text.replace('.main.', '.this.')
    text = text.replace(' "openclaw_nsg" {', ' "this" {')
    text = text.replace('.openclaw_nsg.', '.this.')
    text = text.replace(' "daily" {', ' "this" {')
    text = text.replace('.daily.', '.this.')
    
    with open(fp, 'w') as f:
        f.write(text)

print("Singleton logic applied!")
