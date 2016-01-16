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

def create_dir(new_dir)
  unless File.directory?(new_dir)
    FileUtils.mkdir_p(new_dir)
  end
end

def determine_file_action(src_dir, dest_dir, file_name)
  ret_action = DirAction::NoAction
  if File.exist?(File.join(dest_dir, src_dir, file_name))
    if File.mtime(File.join(src_dir, file_name)) > File.mtime(File.join(dest_dir, src_dir, file_name))
      ret_action = DirAction::Update
    end
  else
    ret_action = DirAction::Create
  end
  return ret_action
end

def process_directory(dir_name, bkup_dir)

  puts " ******* Processing Directory: #{dir_name}"
  total_file = 0
  total_add = 0
  total_update = 0

  # First, process files in this dir
  Find.find(dir_name) do |item|
 
    file_path = File.dirname(item)
    file_name = File.basename(item)

    if FileTest.directory?(item)
      create_dir(File.join(bkup_dir, item))
    else
      total_file += 1
      fileAction = determine_file_action(file_path, bkup_dir, file_name)
      case fileAction
        when DirAction::Create
          FileUtils.cp(item, File.join(bkup_dir, file_path))
          total_add += 1
        when DirAction::Update
          FileUtils.cp(item, File.join(bkup_dir, file_path))
          total_update += 1
      end
    end
  
  end

  puts "   ***  Total Files Added:    #{total_add}"
  puts "   ***  Total Files Updated:  #{total_update}"

end

# -----------------------------------------------------
#  Beginning of main script
# -----------------------------------------------------
config_file = File.read('home_backup.json')
config_hash = JSON.parse(config_file)

backup_dir = File.join(config_hash['backup_directory'] ,
                       config_hash['computer_id'])
create_dir(backup_dir)

config_hash['local_directory'].each{|key, value| process_directory(value, backup_dir)}

puts " *********** Done ************* "
