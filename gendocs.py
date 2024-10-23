#!/usr/bin/env python3
import os
import re
import sys
from datetime import datetime
import subprocess

def is_file_in_git(filepath):
    """Check if a file is tracked in Git."""
    try:
        # Use git ls-files to check if file is tracked
        result = subprocess.run(
            ['git', 'ls-files', '--error-unmatch', filepath],
            capture_output=True,
            text=True,
            check=False  # Don't raise exception on non-zero exit
        )
        return result.returncode == 0
    except FileNotFoundError:
        print("Error: Git is not installed or not in PATH", file=sys.stderr)
        sys.exit(1)
    except subprocess.SubprocessError as e:
        print(f"Error checking Git status: {e}", file=sys.stderr)
        sys.exit(1)

def get_latest_modification(directory):
    """Get the most recent modification date of any file in the directory that's in Git."""
    try:
        # Get the last commit date for the directory
        result = subprocess.run(
            ['git', 'log', '-1', '--format=%cs', directory],
            capture_output=True,
            text=True,
            check=True
        )
        if result.stdout.strip():
            return result.stdout.strip()
        return None
    except subprocess.SubprocessError:
        return None

def extract_readme_info(filepath):
    """Extract H1 heading and first paragraph from README.md file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Find the first H1 heading
        h1_match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
        if not h1_match:
            return None, None
        
        heading = h1_match.group(1).strip()
        
        # Find the first non-empty paragraph after the heading
        paragraphs = content[h1_match.end():].split('\n\n')
        first_para = None
        for p in paragraphs:
            # Skip empty paragraphs and those that look like headers or lists
            cleaned = p.strip()
            if (cleaned and 
                not cleaned.startswith('#') and 
                not cleaned.startswith('-') and 
                not cleaned.startswith('*')):
                first_para = ' '.join(cleaned.split('\n'))
                break
                
        return heading, first_para
    except Exception as e:
        print(f"Error processing {filepath}: {e}", file=sys.stderr)
        return None, None

def generate_table():
    """Generate the markdown table content."""
    # Get all immediate subdirectories
    subdirs = [d for d in os.listdir('.') 
              if os.path.isdir(d) and not d.startswith('.')]
    
    table_lines = []
    table_lines.append("| Path | Description | Last Updated |")
    table_lines.append("|------|-------------|--------------|")
    
    for subdir in sorted(subdirs):  # Sort directories for consistent output
        readme_path = os.path.join(subdir, 'README.md')
        # Only process if file exists and is tracked in Git
        if os.path.exists(readme_path) and is_file_in_git(readme_path):
            heading, paragraph = extract_readme_info(readme_path)
            if heading and paragraph:
                # Get the latest modification date from Git history
                last_updated = get_latest_modification(subdir) or "N/A"
                
                # Combine title and description with markdown formatting
                description = f"**{heading}**<br>{paragraph}"
                
                # Create the table row
                row = f"| [{subdir}]({readme_path}) | {description} | {last_updated} |"
                table_lines.append(row)
    
    return '\n'.join(table_lines)

def update_main_readme():
    """Update the main README.md file between the placeholders."""
    readme_path = './README.md'
    
    try:
        # Read the current content
        with open(readme_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Find the section between placeholders
        start_marker = "<!-- BEGIN_LIST -->"
        end_marker = "<!-- END_LIST -->"
        pattern = f"({start_marker}).*?({end_marker})"
        
        # Generate the new table
        table = generate_table()
        
        # Replace the content between markers with the new table
        new_content = re.sub(
            pattern,
            f"{start_marker}\n{table}\n{end_marker}",
            content,
            flags=re.DOTALL
        )
        
        # Write the updated content back to the file
        with open(readme_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
            
        print(f"Successfully updated {readme_path}")
        
    except FileNotFoundError:
        print(f"Error: {readme_path} not found", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error updating {readme_path}: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    update_main_readme()
