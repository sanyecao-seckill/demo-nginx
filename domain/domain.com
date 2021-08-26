server {
        listen 7081;

        error_log logs/domain-error.log error;
        access_log logs/domain-access.log access;

        set_by_lua_block $user_id {
           return "zhangsan"
        }

        #活动数据查询
        location /activity/query{
            default_type text/plain;
            proxy_pass http://backend;
        }

        #进结算页页面（H5）
        location /settlement/page{
            default_type text/html;
            proxy_pass http://backend;
        }

        #结算页页面初始化渲染所需数据
        location /settlement/initData{
            default_type text/plain;
            proxy_pass http://backend;
        }

        #结算页提交订单
        location /settlement/submitData{
            default_type text/plain;
            proxy_pass http://backend;
        }

        #结算页用户行为操作。模糊匹配
        location ~* /useAction/{
            default_type text/plain;
            proxy_pass http://backend;
        }

        #静态资源匹配,模糊匹配
        location ^~ /images/{
            default_type text/plain;
            proxy_pass http://backend;
        }

}
