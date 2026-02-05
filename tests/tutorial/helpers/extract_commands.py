#!/usr/bin/env python3
"""
Extract shell/bash commands from Markdown files.
This parser extracts code blocks marked as 'shell' or 'bash' from tutorial markdown files.
"""

import re
import sys
from pathlib import Path


def extract_shell_commands(markdown_file):
    """
    Extract shell and bash code blocks from a markdown file.
    
    Args:
        markdown_file: Path to the markdown file
        
    Returns:
        List of command strings
    """
    content = Path(markdown_file).read_text()
    
    # Pattern to match ```shell or ```bash code blocks
    # Supports both ```shell and ```bash
    pattern = r'```(?:shell|bash)\n(.*?)```'
    
    matches = re.findall(pattern, content, re.DOTALL)
    
    commands = []
    for match in matches:
        # Clean up the command block
        command = match.strip()
        if not command:
            continue
            
        # Skip code blocks that are just output examples (no commands)
        # These typically start with paths or don't have actual commands
        lines = command.split('\n')
        
        # Skip if it's just a path or output example
        if all(line.startswith(('/','#', '+', '|', 'Model', 'App', 'Unit', 'Machine', 'NAME', 'd2lj5jgco3bs')) 
               or not line.strip() 
               or line.strip().startswith('Located charm')
               or line.strip().startswith('Deploying')
               for line in lines if line.strip()):
            continue
        
        # Skip blocks that look like command output (no actual commands)
        has_command = any(
            line.strip() and 
            not line.startswith(('+', '#', '|', 'Model', 'App', 'Unit', 'Machine')) and
            not all(c in '-+| ' for c in line)  # Skip table borders
            for line in lines
        )
        
        if has_command:
            commands.append(command)
    
    return commands


def main():
    if len(sys.argv) != 2:
        print("Usage: extract_commands.py <markdown_file>", file=sys.stderr)
        sys.exit(1)
    
    markdown_file = sys.argv[1]
    
    if not Path(markdown_file).exists():
        print(f"Error: File not found: {markdown_file}", file=sys.stderr)
        sys.exit(1)
    
    commands = extract_shell_commands(markdown_file)
    
    if not commands:
        print(f"# No shell/bash commands found in {markdown_file}", file=sys.stderr)
        sys.exit(0)
    
    # Output all commands separated by newlines
    # Add error handling to exit on first failure
    print("set -e  # Exit on any error")
    print("set -x  # Print commands as they execute")
    print()
    
    for i, command in enumerate(commands, 1):
        print(f"# --- Command block {i} ---")
        print(command)
        print()


if __name__ == "__main__":
    main()
