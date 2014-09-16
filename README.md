# Directory Monitor

A simple Ruby script that monitors given directories. When it finds a file whose name contains #tags it moves it to a location specified by configuration rules.

## Usage

### Tagging files

When you download a file to your computer, rename it like this:

```
#foo#bar=somefile.txt
```

By default `#foo` and `#bar` denote tags and `=` separates tags from the actual filename.

You can use the configuration file to change tag prefix and filename separator.

### Running the script

In Windows:

```
path\to\ruby.exe path\to\dirmonitor.rb "x:\temp" "c:\downloads" "path\to\config.yml"
```

The order of parameters is not significant, ie. you may give configuration file first if it pleases you. You can give as many directories as you wish but only one configuration file.

If you feel you only ever need one configuration, you can write your settings directly into the script and ignore the YAML file. The script can handle both scenarios.

### Settings

| Setting					| Value			 | Description |
| --------------- | ---------- | ----------- |
| create_dirs			| true/false | Should missing directories be created automatically? (default: true) |
| overwrite_files | true/false | Should existing files be overwritten? (default: false) |
| check_interval	| int				 | At what interval directory is checked (in seconds) (default: 60) |
| tag_prefix			| string		 | What is the prefix for tags (default: "#") |
| filename_prefix | string		 | What character(s) separates the tags from the actual filename (default: "=") |
| skip_part_files | true/false | Should files with .part extension be skipped? (default: true) |

## Example

See dirmonitor_sample.yml for example configuration.
