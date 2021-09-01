--通过请求URL获取产品编号
local param_st = ngx.var.arg_st
if param_st == nil then
    param_st = ""
end
ngx.var.st = param_st

local param_product_id = ngx.var.arg_productId
if param_product_id == nil then
    param_product_id = ""
end
ngx.var.product_id = param_product_id

ngx.log(ngx.ERR,"*********do set by lua***********")

--通过cookie获取用户ID
return ngx.var.cookie_userId