# Chrome Tab Management Scripts

Two AppleScript utilities for managing Chrome tabs efficiently.

## Scripts Overview

### 1. chrome-tab-cleanup.scpt
Finds and removes duplicate tabs across all Chrome windows with detailed preview.

### 2. chrome-tab-organizer.scpt
Collects all tabs from multiple windows and organizes them in a single window, sorted by domain or full URL.

## Features

### Tab Cleanup Script
- **Smart duplicate detection** - Ignores URL parameters and fragments
- **Preview before closing** - Shows exactly which tabs will be closed
- **Whitelist protection** - Protects localhost and specified domains
- **Comprehensive reporting** - Shows summary of tabs processed and closed
- **Safe operation** - Confirmation dialogs and cancel support

### Tab Organizer Script
- **Two sorting modes** - Sort by domain or full URL
- **Window consolidation** - Moves all tabs to a single window
- **Command line arguments** - Flexible configuration options
- **Preview confirmation** - Shows tab count before organizing
- **Bubble sort algorithm** - Reliable alphabetical sorting

## Installation

1. Download both `.scpt` files
2. Make them executable:
   ```bash
   chmod +x chrome-tab-cleanup.scpt
   chmod +x chrome-tab-organizer.scpt
   ```

## Usage

### Tab Cleanup
```bash
# Basic cleanup with confirmation
osascript chrome-tab-cleanup.scpt
```

**Configuration options** (edit script properties):
- `silentMode`: Disable terminal output
- `showConfirmation`: Skip confirmation dialog
- `normalizeUrls`: Enable/disable URL normalization
- `whitelistDomains`: Protect specific domains

### Tab Organizer
```bash
# Basic organization (sorts by domain)
osascript chrome-tab-organizer.scpt

# Sort by full URL instead of domain
osascript chrome-tab-organizer.scpt --sort-by-url
osascript chrome-tab-organizer.scpt -u

# Silent mode (no audio feedback)
osascript chrome-tab-organizer.scpt --silent
osascript chrome-tab-organizer.scpt -s

# Skip confirmation dialog
osascript chrome-tab-organizer.scpt --no-confirm
osascript chrome-tab-organizer.scpt -n

# Combine options
osascript chrome-tab-organizer.scpt -u -s -n

# Show help
osascript chrome-tab-organizer.scpt --help
osascript chrome-tab-organizer.scpt -h
```

## Command Line Options (Organizer)

| Option | Short | Description |
|--------|-------|-------------|
| `--sort-by-url` | `-u` | Sort by full URL instead of domain |
| `--sort-by-domain` | `-d` | Sort by domain (default) |
| `--silent` | `-s` | Silent mode (no audio feedback) |
| `--no-confirm` | `-n` | Skip confirmation dialog |
| `--help` | `-h` | Show help message |

## How It Works

### Duplicate Detection
The cleanup script identifies duplicates by:
1. **Normalizing URLs** - Removes query parameters (`?`) and fragments (`#`)
2. **Comparing base URLs** - `example.com/page?param=1` = `example.com/page`
3. **Preserving first occurrence** - Keeps the first tab, closes duplicates
4. **Respecting whitelist** - Skips localhost and specified domains

### URL Sorting Examples
**Domain sorting** groups by website:
```
github.com (all GitHub tabs)
google.com (all Google tabs)
stackoverflow.com (all Stack Overflow tabs)
```

**Full URL sorting** sorts alphabetically:
```
https://docs.google.com/document/abc
https://docs.google.com/document/xyz
https://docs.google.com/presentation/abc
```

## Safety Features

- ✅ **Confirmation dialogs** before any destructive actions
- ✅ **Preview functionality** shows exactly what will be changed
- ✅ **Cancel support** - ESC or Cancel button exits cleanly
- ✅ **Error handling** - Graceful failure with user-friendly messages
- ✅ **Whitelist protection** - Prevents closing important local development tabs

## Requirements

- **macOS** with AppleScript support
- **Google Chrome** browser
- **Terminal access** for command line usage

## Troubleshooting

### Chrome Not Found
- Ensure Google Chrome is installed and running
- Grant necessary permissions if prompted

### Permission Issues
- You may need to grant Terminal or Script Editor accessibility permissions
- Go to System Preferences > Security & Privacy > Privacy > Accessibility

### Script Errors
- Ensure Chrome is the active application
- Close any Chrome dialogs that might block automation
- Try running with Chrome as the frontmost application

## Configuration

Both scripts include configuration properties at the top that can be modified:

### Cleanup Script Properties
```applescript
property silentMode : false
property showConfirmation : true
property normalizeUrls : true
property whitelistDomains : {"localhost", "127.0.0.1"}
```

### Organizer Script Properties
```applescript
property silentMode : false
property showConfirmation : true
property sortByDomain : false  -- false = sort by full URL
```

## Examples

### Typical Cleanup Workflow
1. Run cleanup script
2. Review preview of duplicate tabs
3. Confirm or cancel operation
4. View summary report

### Typical Organization Workflow
1. Run organizer with desired options
2. Review tab count and confirmation
3. Confirm consolidation and sorting
4. All tabs organized in single window

## Notes

- **Backup important work** before running scripts
- **Test with a few tabs first** to understand behavior
- **Scripts work best** when Chrome is the active application
- **URL normalization** removes tracking parameters for better duplicate detection