-- 活动查询

-- 共享内存区域，用于保存活动数据
local activity = ngx.shared.activity

-- 通过全局变量获取productId
local product_id = ngx.var.product_id
if not product_id then
    ngx.say("")
    return
end

-- 优先查询缓存
local activity_info = activity:get("activity_"..product_id)

if not activity_info or activity_info == "" then
    ngx.log(ngx.ERR,"local activity is null!")

    -- 将请求通过upstream分发给后端Web服务
    local res = ngx.location.capture("/activity/subQuery",{ args = { productId = product_id }})
    if not res or res.status ~=200 then
        ngx.say("")
        return
    end

    activity_info = res.body

    -- 将活动信息缓存到本地,有效期10分钟
    activity:set("activity_"..product_id,activity_info,10*60)
end

-- 将活动信息返回
ngx.say(activity_info)
return
