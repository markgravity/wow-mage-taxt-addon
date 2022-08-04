function setmetatables(t1, t2)
	local t1Metatable = getmetatable(t1)
	setmetatable(t1, t2)
	if t1Metatable == nil then
		return
	end

	for k,v in pairs(t1Metatable) do
		if k ~= '__index' and t1[k] ~= nil then
			local override = t1[k]
			t1[k] = function(self, ...)
				return override(
					self,
					function(...)
						v(self,...)
					end,
					...
				)
			end
		else
			t1[k] = v
		end
	end
end

function table.merge(t1, t2)
	if table.isArray(t1) then
		for _, v in ipairs(t2) do
		  table.insert(t1, v)
		end
		return
	else
		for k, v in pairs(t2) do
			t1[k] = v
		end
		return
	end
end

function table.isArray(t)
  return #t > 0 and next(t, #t) == nil
end

local function dump(o, tbs, tb)
	tb = tb or 0
	tbs = tbs or '  '
	if type(o) == 'table' then
		local s = '{'
		if (next(o)) then s = s .. '\n' else return s .. '}' end
		tb = tb + 1
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"' .. k .. '"' end
			s = s .. tbs:rep(tb) .. '[' .. k .. '] = ' .. dump(v, tbs, tb)
			s = s .. ',\n'
		end
		tb = tb - 1
		return s .. tbs:rep(tb) .. '}'
	else
		return tostring(o)
	end
end

function table.print(t)
	print(dump(t))
end
