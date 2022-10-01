local M = {}

-- M.icons = {
-- 	Class = " ",
-- 	Color = " ",
-- 	Constant = " ",
-- 	Constructor = " ",
-- 	Enum = "了 ",
-- 	EnumMember = " ",
-- 	Field = " ",
-- 	File = " ",
-- 	Folder = " ",
-- 	Function = " ",
-- 	Interface = "ﰮ ",
-- 	Keyword = " ",
-- 	Method = "ƒ ",
-- 	Module = " ",
-- 	Property = " ",
-- 	Snippet = "﬌ ",
-- 	Struct = " ",
-- 	Text = " ",
-- 	Unit = " ",
-- 	Value = " ",
-- 	Variable = " ",
-- }

M.icons = {
	File = " ",
	Module = " ",
	Namespace = " ",
	Package = " ",
	Class = " ",
	Method = " ",
	Property = " ",
	Field = " ",
	Constructor = " ",
	Enum = " ",
	Interface = " ",
	Function = " ",
	Variable = " ",
	Constant = " ",
	String = " ",
	Number = " ",
	Boolean = " ",
	Array = " ",
	Object = " ",
	Key = " ",
	Null = " ",
	EnumMember = " ",
	Struct = " ",
	Event = " ",
	Operator = " ",
	TypeParameter = " ",
}

function M.cmp_format()
	return function(_entry, vim_item)
		if M.icons[vim_item.kind] then
			vim_item.kind = M.icons[vim_item.kind] .. vim_item.kind
		end
		return vim_item
	end
end

return M
