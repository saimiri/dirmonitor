# Directory Monitor

A simple Ruby script that monitors given directories. When it finds a file whose name contains #tags it moves it to a location specified by configuration rules.

## Usage

### Tag files

When you download a file to your computer, rename it like this:

```
#foo#bar=somefile.txt
```

By default `#foo` and `#bar` denote tags and `=` separates tags from the actual filename.

You can use the configuration file to change tag prefix and filename separator.

### Set up rules

Create a YAML file similar to the example below:

```yaml
rules:
  - path: "/some/target/path/foo"
    tags: "foo"
  - path: "/some/target/path/foobar"
    tags: "foo, bar"
  - path: "/var/sort_later/*"
    tags: "other"
```
Using the above rules, the tag `#foo` would move the file to `/some/target/path/foo`, whereas using tags `#foo` and `#bar` both would move it to `/some/target/path/foobar`.

The rules are applied using the following logic:

 * An exact tag match is immediately applied and the rest of the rules are ignored.
 * Filename must contain every tag in the rule for it to match.
 * Filename may contain more tags than a rule has. In that case, the rule that matches the most tags will be applied.

If the path ends with a slash and an asterisk (`/*`) all the extra tags in the filename that are not present in the rule will be used to create an additional path under the rule path.

For example: Using the rules presented previously tagging file as `#other#pretty#flowers=daffodil.jpg` would place it in `/var/sort_later/pretty/flowers/daffodil.jpg`.

If you feel you only ever need one configuration, you can write your rules (and other settings) directly into the script and ignore the YAML file. The script can handle both scenarios. See inline documentation for details.

### Run the script

In Windows:

```
path\to\ruby.exe path\to\dirmonitor.rb "x:\temp" "c:\downloads" "path\to\config.yml"
```

The order of parameters is not significant, ie. you may give configuration file first if it pleases you. You can give as many directories as you wish but only one configuration file.

### Fine tune other settings

| Setting					| Value			 | Description |
| --------------- | ---------- | ----------- |
| create_dirs			| true/false | Should missing directories be created automatically? (default: true) |
| overwrite_files | true/false | Should existing files be overwritten? (default: false) |
| check_interval	| int				 | At what interval directory is checked (in seconds) (default: 60) |
| tag_prefix			| string		 | What is the prefix for tags (default: "#") |
| filename_prefix | string		 | What character(s) separates the tags from the actual filename (default: "=") |
| skip_part_files | true/false | Should files with .part extension be skipped? (default: true) |

## Please note

  1. Only forward slashes are currently supported in the rule paths. They work fine in Windows.
  2. When creating additional directories from extra tags the script currently applies them in the order they are given. Therefore `#foo#bar` will result in different directory structure than `#bar#foo`. I'm planning to fix this if I figure out a sensible way to do it.

## Configuration example

This is from the `dirmonitor_sample.yml` found in the src folder.

```yaml
# Create missing directories
create_dirs : true
# Do not overwrite existing files
overwrite_files : false
# Check specified directory/ies every 30 seconds
check_interval : 30
rules:
   # Matches if filename contains #foo and #bar both but no other tags
 - path : "z:/foobar"
   tags : "foo, bar"
   # Matches if filename contains only #images but no other tags
 - path : "z:/fubar/images"
   tags : "images"
  # Asterisk means that only #misc needs to match and every other
  # tag is used to create nested directories under z:/dumpster
 - path : "z:/dumpster/*"
   tags : "misc"
```