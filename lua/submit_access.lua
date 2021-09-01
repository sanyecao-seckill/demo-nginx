-- 引入黑名单相关的缓存
local black_cache = require "black_user_cache"

local user_id = ngx.var.user_id

-- 统计key，就用user_id
local key = user_id

-- 校验是否在黑名单
local flag = black_cache.check(user_id)
if flag == false then
    ngx.log(ngx.ERR,key.." is in black list!")
    return ngx.exit(500)
end

-- 校验是否触碰黑名单生成规则
flag = black_cache.filter(user_id)
if flag == false then
    return ngx.exit(500)
end

-- 校验st是否合法
local _st = ngx.md5(ngx.var.user_id.."3")
if _st ~= ngx.var.st then
    ngx.log(ngx.ERR,key.." st is invalid!")
    return ngx.exit(500)
end