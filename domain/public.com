#公用location


#活动数据查询
location /activity/subQuery{
    proxy_pass http://backend;
}

#错误页
location = /html_fail.html {
    default_type text/html;
    root /Users/wangzhangfei5/Documents/seckillproject/demo-nginx/html;
}

#以"@"开头定义的location，是内部接口，外部无法访问
location @json_fail {
    default_type application/json;
    return 200 '{"code":"200001","message":"nginx intercept！！！"}';
}


