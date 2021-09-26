-- 活动预热功能

-- 共享内存区域，用于保存活动数据
local activity = ngx.shared.activity

-- 通过URL入参，获取产品编号
local product_id = ngx.var.arg_productId
if not product_id then
    ngx.say("{\"code\":\"200001\",\"message\":\"productId is null!\"}")
    return
end

-- 将请求通过upstream分发给后端Web服务
local res = ngx.location.capture("/activity/subQuery",{ args = { productId = product_id }})

if not res or res.status ~=200 then
    ngx.say("{\"code\":\"200001\",\"message\":\"activity is null!\"}")
    return
end

-- 将活动信息缓存到本地,有效期10分钟
activity:set("activity_"..product_id,res.body,10*60)

ngx.say("{\"code\":\"200\",\"message\":\"success\"}")
return
