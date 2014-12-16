require 'aws-sdk'
require 'date'
require 'zlib'
require 'debugger'

# load AWS library
id = ENV['ADLER_AWS_ACCESS_KEY_ID']
key = ENV['ADLER_AWS_SECRET_ACCESS_KEY']
AWS.config  access_key_id: id , secret_access_key: key
s3 = ::AWS::S3.new

# get the backup bucket
bucket = s3.buckets['adler-backups']

#form backup command 
date_stamp = DateTime.now.strftime("%Y%m%dT%H%M%S");
db_user = "drupal_user"
db_name = "drupal"
db_pwd  = ENV["DRUPAL_DB_PWD"]
backup_file_name = "drupal_backup_#{date_stamp}.sql"
backup_command = "mysqldump -u #{db_user} -p#{db_pwd} --single-transaction -r #{backup_file_name} #{db_name}"

puts backup_command

#run backup command
command_ran_ok = system(backup_command)
if command_ran_ok
  puts "Backup command ran fine"
else
  puts "Backup command abended"
end

#compress backup file
compressed_backup_name = backup_file_name + ".gz"
Zlib::GzipWriter.open(compressed_backup_name) do |gz|
  gz.mtime = File.mtime(backup_file_name)
  file = File.open(backup_file_name)
  gz << File.read(file)
  file.close
  gz.close
end

#ship file to Amazon bucket
compressed_backup_path = Pathname(compressed_backup_name)
prefix = "drupal"
# throw backup file in s3 bucket
object_name = "#{prefix}/#{compressed_backup_name}"
bucket.objects[object_name].write(compressed_backup_path, :acl => 'private')

if bucket.objects[object_name].exists?
  puts "Successful backup to S3" 
  File.delete(compressed_backup_name)
  File.delete(backup_file_name)
else
  puts "bucket write failed"
end