-- 黑名单缓存功能

local _CACHE = {}
-- 共享内存区域，用于统计黑名单以及保存黑名单
local hole = ngx.shared.black_hole
-- 请求计数key的前缀
local count_prefix = "co_"
-- 黑名单key的前缀
local black_prefix = "bl_"
-- 过滤请求，如果没有触碰黑名单规则，则返回true,反之则返回false
function _CACHE.filter(key)
    --  参数1 key, 参数2 步长，参数3 如果key不存在时的初始化值 ,参数4 初始化值的失效时间
    local after_count = hole:incr(count_prefix..key, 1, 0, 1)
    -- 如果为空，则是异常了，这里不做拦截，防止误杀
    if not after_count then
       return true
    end
    -- 判断1秒内的请求频率，如果大于设定阈值，则加入黑名单
    if after_count > 1 then
        ngx.log(ngx.ERR,key.." was caught ！！！")
        -- 存入本地cache,有效期15秒
        local suc, err = hole:set(black_prefix..key,1,15)
        if not suc
        then
            ngx.log(ngx.ERR,key.." set to cache fail : "..err)
        end
        return false
    end
    return true
end
-- 校验是否合法，如果在黑名单，则返回false，如果不在，则返回true
function _CACHE.check(key)
    local value = hole:get(black_prefix..key)
    if not value then
        return true
    end
    return false
end
return _CACHE