#内部接口，提供预热、监控等接口，外网无法访问
server {
        listen 7082;

        error_log logs/internal-error.log error;
        access_log logs/internal-access.log access;
        default_type text/plain;
        charset utf-8;

        #活动预热
        location /activity/preLoad{
            #deny all;
            #allow 127.0.0.1;
            content_by_lua_file /Users/wangzhangfei5/Documents/seckillproject/demo-nginx/lua/activity_pre_load.lua;
        }

        #测试请求头
        location /mock/testHeader{
           proxy_pass http://backend;
        }


        include /Users/wangzhangfei5/Documents/seckillproject/demo-nginx/domain/public.com;
}
