
local _CACHE = {}
-- 共享内存区域，用于统计黑名单以及保存黑名单
local hole = ngx.shared.black_hole

-- 过滤请求，如果没有触碰黑名单规则，则返回true,反之则返回false
-- 按条件统计1秒内的频率，如果大于设定阈值，则认定为非法流量，放入黑明
function _CACHE.filter(key)
    --  参数1 key, 参数2 步长，参数3 如果key不存在时的初始化值 ,参数4 初始化值的失效时间
    local after_count  = hole:incr(key, 1, 0, 1)
    -- 如果为空，则是异常了，这里不做拦截，防止误杀
    if after_count == nil then
       return false
    end
    -- 如果大于设定阈值，则加入黑名单
    if after_count > 1 then
        ngx.log(ngx.ERR,key.." was caught ！！！")
        -- 存入本地cache,有效期15秒
        local suc, err = hole:set(key,1,15)
        if suc == nil or not suc
        then
            ngx.say(ngx.ERR,key.." set to cache fail : "..err)
        end
        return false
    end
    return true
end

-- 校验是否合法，如果在黑名单，则返回false，如果不在，则返回true
function _CACHE.check(key)
    local value = hole:get(key)
    if value == nil or value == "" then
        return true
    end
    return false
end

return _CACHE