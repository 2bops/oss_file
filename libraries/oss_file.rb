require 'rest-client'
require 'time'
require 'openssl'
require 'base64'

module OSSFileLib
  BLOCKSIZE_TO_READ = 1024 * 1000
  RestClient.proxy = ENV['http_proxy']
  
  def self.build_headers(date, authorization)
    headers = {
      :date => date,
      :authorization => authorization
    }
    return headers
  end
  
  def self.get_md5_from_oss(bucket,path,oss_access_key_id,oss_secret_access_key,region,internal)
    now, auth_string = get_oss_auth("HEAD", bucket,path,oss_access_key_id,oss_secret_access_key)

    headers = build_headers(now, auth_string)
    region = "hangzhou" if region.nil?
    endpoint = build_endpoint(region,internal)
    response = RestClient.head('http://%s.%s%s' % [bucket,endpoint,path], headers)

    etag = response.headers[:etag].gsub('"','')
    return etag
  end

  def self.get_from_oss(bucket,path,oss_access_key_id,oss_secret_access_key,region,internal)
    now, auth_string = get_oss_auth("GET", bucket,path,oss_access_key_id,oss_secret_access_key)

    headers = build_headers(now, auth_string)
    region = "hangzhou" if region.nil?
    endpoint = build_endpoint(region,internal)
    response = RestClient::Request.execute(:method => :get, :url => 'http://%s.%s%s' % [bucket,endpoint,path], :raw_response => true, :headers => headers)

    return response
  end

  def self.get_oss_auth(method, bucket,path,oss_access_key_id,oss_secret_access_key)
    now = Time.now().utc.strftime('%a, %d %b %Y %H:%M:%S GMT')
    string_to_sign = "#{method}\n\n\n%s\n" % [now]
    
    
    string_to_sign += "/%s%s" % [bucket,path]

    digest = digest = OpenSSL::Digest::Digest.new('sha1')
    signed = OpenSSL::HMAC.digest(digest, oss_secret_access_key, string_to_sign)
    signed_base64 = Base64.encode64(signed)

    auth_string = 'OSS %s:%s' % [oss_access_key_id,signed_base64]
        
    [now,auth_string]
  end


  def self.verify_md5_checksum(checksum, file)
    oss_md5 = checksum
    local_md5 = Digest::MD5.new

    # buffer the checksum which should save RAM consumption
    File.open(file, "rb") do |fi|
      while buffer = fi.read(BLOCKSIZE_TO_READ)
        local_md5.update buffer
      end
    end

    Chef::Log.debug "md5 of remote object is #{oss_md5}"
    Chef::Log.debug "md5 of local object is #{local_md5.hexdigest}"

    local_md5.hexdigest == oss_md5.downcase
  end

  def self.build_endpoint(region,internal)
      endpointlist = {
          "qingdao" => "oss-cn-qingdao.aliyuncs.com",
          "beijing" => "oss-cn-beijing.aliyuncs.com",
          "hangzhou" => "oss-cn-hangzhou.aliyuncs.com",
          "hongkong" => "oss-cn-hongkong.aliyuncs.com",
          "shenzhen" => "oss-cn-shenzhen.aliyuncs.com",
          "shanghai" => "oss-cn-shanghai.aliyuncs.com",
          "ap-southeast-1" => "oss-ap-southeast-1.aliyuncs.com",
          "us-west-1" => "oss-us-west-1.aliyuncs.com",
          "us-east-1" => "oss-us-east-1.aliyuncs.com"
      }
    if internal
      return endpointlist[region].sub(/.aliyuncs/,'-internal.aliyuncs')
    else
      return endpointlist[region]
    end
  end

end
