# encoding: utf-8
require 'fileutils'
require 'yaml'
require 'date'

# A simple Ruby script that monitors given directories. When it finds a file
# whose name contains #tags it moves it to a location specified by
# configuration rules. See dirmonitor_sample.yml for example configuration.
# 
# Author::      Juha Auvinen (info.pleasenospam@saimiri.fi)
# Copyright::   Copyright 2014 Saimiri Design
# License::     Apache 2.0

# You can define settings here or use a separate YAML file.
# 
# Use Asterix at the end of a path to mark it as a dumping ground for unmatched
# tags. Unmatched tags will be used to create directories under rule path.
# 
# Example:
#   RULE: path => z:/misc/*, tags => ["misc"]
#   FILE TAGS: #misc #foo #bar
#   PRODUCES: z:/misc/foo/bar/{filename}
# 
# Use this format to define rules:
# rules = [
#   {"path" => "z:/foobar", "tags" => ["foo", "bar"] },
#   {"path" => "z:/misc/*", "tags" => ["misc"] }
# ]

# Rules for file handling
rules = []

# Should missing directories be created automatically?
create_dirs = true

# Should existing files be overwritten?
overwrite_files = false

# At what interval directory is checked (in seconds)
check_interval = 60

# What is the prefix for tags
tag_prefix = '#'

# What character(s) separates the tags from the actual filename
filename_prefix = '='

# Browsers user .part extension for incomplete downloads so it's not a
# good idea to move them around. Unless you really know what you're doing.
skip_part_files = true

# CODE STARTS ------------------------------------------------------------------

# Config file
config = false

# Is a directory/set of directories being checked at this very moment?
check_running = false

# A list of directories to monitor
source_dirs = []

# Has user signaled for the script to be interrupted?
interrupted = false

# How many checks have been made in total
checks_done = 0;

# We indent some lines for easier reading
indent = "    "

# Parse command line arguments. Assume one may be YAML config file, others
# are directories to be monitored.
ARGV.each_index do |i|
  if ARGV[i].index(".yml") != nil
    config = YAML.load_file(ARGV[i])
  else
    source_dirs << ARGV[i]
  end
end

# If config file was found, parse it and use it to override default settings.
if config
  rule_list = config["rules"]
  rules = []
  rule_list.each do |rule|
    tags = rule["tags"].gsub(", ", ",").split(",")
    rules << { "path" => rule["path"], "tags" => tags }
  end
  create_dirs = config["create_dirs"] || create_dirs
  overwrite_files = config["overwrite_files"] || overwrite_files
  check_interval = config["check_interval"] || check_interval
  filename_prefix = config["filename_prefix"] || filename_prefix
  tag_prefix = config["tag_prefix"] || tag_prefix
  skip_part_files = config["skip_part_files"] || skip_part_files
end

# Trap CTRL-C as a signal to exit the script. Do not exit if a directory
# check is running.
trap("INT") {
  interrupted = true
  if check_running == false
    puts "Exiting script"
    exit
  else
    puts "Exiting after check is complete"
  end
}

puts "Press Ctrl-C to exit"
puts "--------------------------------------------------"

# The main loop
until interrupted do
  check_running = true
  checks_done = checks_done + 1
  current_time = Time.now.strftime("%H:%M:%S")
  puts "Round #{checks_done} @ #{current_time}"
  source_dirs.each do |source_dir|
    if !File.directory?(source_dir)
      puts "#{indent}#{source_dir} doesn't exist. Skipping..."
      next
    end
    puts "#{indent}Checking #{source_dir}"
    Dir.foreach(source_dir) do |item|
      if item[0] == tag_prefix
        if item[-5..-1] == ".part" && skip_part_files
          next          
        end
        nameparts = item.split(filename_prefix)
        # Returns the tags (removes the first, empty one)
        tags = nameparts[0].split(tag_prefix)[1..-1]
        
        matched_path = ''
        best_matching_rule = -1
        best_match_tag_count = 0
        
        rules.each_index do |i|
          ruletags = rules[i]['tags']
          
          # If the rule has more tags than filename, it cannot match
          if ruletags.length <= tags.length
            # Get common tags from the two arrays
            intersection = tags & ruletags
            int_length = intersection.length
            
            if int_length > 0 && int_length >= best_match_tag_count
              best_match_tag_count = int_length
              best_matching_rule = i
              if int_length == tags.length
                break
              end
            end
          end
          
        end # rules.each_index
        
        if best_match_tag_count == 0
          puts "#{indent}#{indent}No match found for #{item}"
          next
        else
          the_rule = rules[best_matching_rule]
          is_dump_rule = the_rule['path'][-1] == '*'
          
          if is_dump_rule
            # TODO: There should be some logic in ordering extra tags, so that
            # #foo#bar creates same directory structure as #bar#foo. Now they
            # are used in the order given, which may not be the best choice.
            # At least it should be an option.
            tag_diff = tags - the_rule['tags']
            matched_path = the_rule['path'][0..-2] + tag_diff.join('/')
          else
            matched_path = the_rule['path']
          end
        end
        
        # At this point we should have a target path. If not, there is a bug. =(
        if !File.directory?(matched_path)
          if create_dirs == true
            puts "#{indent}#{indent}#{matched_path} doesn't exist, creating directory..."
            # TODO: Add error checking here
            FileUtils.mkdir_p(matched_path)
          else
            puts "#{indent}#{indent}#{matched_path} doesn't exist, create_dirs == false. Skipping..."
            next
          end
        end
        
        source_file = source_dir + '/' + item
        target_file = matched_path + '/' + nameparts.last

        if !File.file?(target_file) || overwrite_files
          puts "#{indent}#{indent}Moving #{source_file}"
          puts "#{indent}#{indent} => #{target_file}"
          FileUtils.mv(source_file, target_file)
        else
          puts "#{indent}#{indent}#{target_file} exists, overwrite_files == false. Skipping..."
          next
        end
      end # if item[0]
    end # Dir.foreach
  end # source_dirs.each
  check_running = false
  if interrupted
    exit
  end
  puts "Sleeping for #{check_interval} seconds... (-.-)zzZ"
  puts "--------------------------------------------------"
  sleep check_interval
end # until interrupted do
