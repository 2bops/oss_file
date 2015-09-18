oss_file Cookbook
=================
- 参考s3_file写的一个阿里云OSS对象存储的chef cookbook,可以拉取存储在OSS上的文件
虽然精简了很多东西,但是阿里云下载文件的速度还是不错的!考虑到跨机房问题,是用的都是
OSS的公网地址,如果只在一个机房使用,可以考虑替换成internal地址.


- region属性
 - qingdao
 - beijing
 - hangzhou
 - beijing
 - shenzhen
 - shanghai
 - us-west-1
 - ap-southeast-1

Example:

    oss_file "/local/dir/filename" do
        remote_path "/oss/dir/filename"
        bucket "oss-bucket"
        oss_access_key_id "access_id"
        oss_secret_access_key "secret_key"
        region "shanghai"
        owner "root"
        group "root"
        mode "0644"
        action :create
    end



