#!/usr/bin/env ruby

require 'find'
require 'date'
require 'json'
require 'fileutils'

module DirAction
  NoAction = 1
  Create = 2
  Update = 3
  Delete = 4
end

def create_dir(dir_name, sub_dir_name)
  new_dir = File.join(dir_name, sub_dir_name)
  unless File.directory?(new_dir)
    puts " Creating Directory #{new_dir}"
    FileUtils.mkdir_p(new_dir)
  end
end

def determine_file_action(src_dir, dest_dir, file_name)
  ret_action = DirAction::NoAction
  if File.exist?(File.join(dest_dir, file_name))
    if File.mtime(File.join(src_dir, file_name)) > File.mtime(File.join(dest_dir, file_name))
      ret_action = DirAction::Update
    end
  else
    ret_action = DirAction::Create
  end
end

def process_directory(dir_name, bkup_dir)

  puts " ******* Processing Directory: #{dir_name}"

  dest_dir = File.join(bkup_dir, dir_name)
  #puts " ********** Destination Directory: #{dest_dir}"
  create_dir(bkup_dir, dir_name)

  # First, process files in this dir
  Find.find(dir_name) do |item|
  
    next if FileTest.directory?(item)
    fileAction = determine_file_action(dir_name, dest_dir, item)
    case fileAction
      when DirAction::Create
        FileUtils.cp(item, dest_dir)
      when DirAction::Update
        FileUtils.cp(item, dest_dir)
    end
    puts " *********** action for #{item} is #{fileAction}"
  
  end

  # Next, process sub-directories
  Dir.chdir(dir_name)
  Dir.glob("**/") do |item| 
    if File.directory?(item)
      puts " sub-dir #{item}" 
      process_directory(File.join(dir_name, item), bkup_dir)
      Dir.chdir(dir_name)
    end
  end

end

# -----------------------------------------------------
#  Beginning of main script
# -----------------------------------------------------
config_file = File.read('home_backup.json')
config_hash = JSON.parse(config_file)

backup_dir = File.join(config_hash['backup_directory'] ,
                       config_hash['computer_id'])
create_dir(config_hash['backup_directory'], config_hash['computer_id'])

config_hash['local_directory'].each{|key, value| process_directory(value, backup_dir)}

puts " *********** Done ************* "
