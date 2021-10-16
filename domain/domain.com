server {
        listen 7081;

        #设置真实的域名
        #server_name  test.com;
        #设置header中的host
        #proxy_set_header Host test.com;

        error_log logs/domain-error.log error;
        access_log logs/domain-access.log access;
        default_type text/plain;
        charset utf-8;


        #security token
        set $st "";

        #产品编号
        set $product_id "";

        #用户ID
        set_by_lua_file $user_id /Users/wangzhangfei5/Documents/seckillproject/demo-nginx/lua/set_common_var.lua;

        #活动数据查询
        location /activity/query{
            limit_req zone=limit_by_user nodelay;
            content_by_lua_file /Users/wangzhangfei5/Documents/seckillproject/demo-nginx/lua/activity_query.lua;
            #设置返回的header，并将security token放在header中
            header_filter_by_lua_block{
               ngx.header["st"] = ngx.md5(ngx.var.user_id.."1")
               --这里为了解决跨域问题设置的，不存在跨域时不需要设置以下header
               ngx.header["Access-Control-Expose-Headers"] = "st"
               ngx.header["Access-Control-Allow-Origin"] = "http://localhost:8080"
               ngx.header["Access-Control-Allow-Credentials"] = "true"
            }
        }

        #进结算页页面（H5）
        location /settlement/prePage{
            default_type text/html;
            rewrite_by_lua_block{
                --校验活动查询的st
                local _st = ngx.md5(ngx.var.user_id.."1")
                --校验不通过时，以500状态码，返回对应错误页
                if _st ~= ngx.var.st then
                  ngx.log(ngx.ERR,"st is not valid!!")
                  return ngx.exit(500)
                end
                --校验通过时，再生成个新的st，用于下个接口校验
                local new_st = ngx.md5(ngx.var.user_id.."2")
                --ngx.exec执行内部跳转,浏览器URL不会发生变化
                --ngx.redirect(url,status) 其中status为301或302
                local redirect_url = "/settlement/page".."?productId="..ngx.var.product_id.."&st="..new_st
                return ngx.redirect(redirect_url,302)
            }
            error_page 500 502 503 504 /html_fail.html;
        }

        #进结算页页面（H5）
        location /settlement/page{
            default_type text/html;
            proxy_pass http://backend;
            error_page 500 502 503 504 /html_fail.html;
        }

        #结算页页面初始化渲染所需数据
        location /settlement/initData{
            access_by_lua_block{
               local _st = ngx.md5(ngx.var.user_id.."2")
               if _st ~= ngx.var.st then
                 return ngx.exit(500)
               end
            }
            proxy_pass http://backend;
            header_filter_by_lua_block{
               ngx.header["st"] = ngx.md5(ngx.var.user_id.."3")
               ngx.header["Access-Control-Expose-Headers"] = "st"
            }
            error_page 500 502 503 504 @json_fail;
        }

        #结算页提交订单
        location /settlement/submitData{
            access_by_lua_file /Users/wangzhangfei5/Documents/seckillproject/demo-nginx/lua/submit_access.lua;
            proxy_pass http://backend;
            error_page 500 502 503 504 @json_fail;
        }

        #结算页用户行为操作。模糊匹配
        location ~* /useAction/{
            proxy_pass http://backend;
        }

        #静态资源匹配,模糊匹配，如果静态资源上到CDN，这里就可以不用了
        location ^~ /images/{
            set_by_lua_block $user_id{
            }
            proxy_pass http://backend;
        }

        #模拟登录
        location /login{
            content_by_lua_block{
              local user_id = ngx.var.arg_user_id
              ngx.header['Set-Cookie'] = 'user_id='..user_id..';path=/; Expires=' .. ngx.cookie_time(ngx.time() + 60 * 60*24)
              ngx.say("login success！！！")
            }
        }

        include /Users/wangzhangfei5/Documents/seckillproject/demo-nginx/domain/public.com;

}
