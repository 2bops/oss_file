require 'digest/md5'
require 'rest-client'
require 'json'

use_inline_resources

action :create do
  download = true

  # handle key specified without leading slash
  remote_path = ::File.join('', new_resource.remote_path)

  # we need credentials to be mutable
  oss_access_key_id = new_resource.oss_access_key_id
  oss_secret_access_key = new_resource.oss_secret_access_key
  region = new_resource.region
  internal = new_resource.internal

  # if credentials not set, raise 
  if oss_access_key_id.nil? && oss_secret_access_key.nil? 
    raise 'No OSS Access Key and Secret'
  end

  if ::File.exists?(new_resource.path)
   oss_md5 = OSSFileLib::get_md5_from_oss(new_resource.bucket, remote_path, oss_access_key_id, oss_secret_access_key,region,internal)

   if OSSFileLib::verify_md5_checksum(oss_md5,new_resource.path)
     Chef::Log.debug 'Skipping download, md5sum of local file matches file in OSS.'
     download = false
   end
  end

  if download
    response = OSSFileLib::get_from_oss(new_resource.bucket, remote_path, oss_access_key_id, oss_secret_access_key,region,internal)

    ::FileUtils.mv(response.file.path, new_resource.path)
  end

  f = file new_resource.path do
    action :create
    owner new_resource.owner || ENV['user']
    group new_resource.group || ENV['user']
    mode new_resource.mode || '0644'
  end

  new_resource.updated_by_last_action(download || f.updated_by_last_action?)
end
