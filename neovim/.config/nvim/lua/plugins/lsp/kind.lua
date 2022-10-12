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
	Array = " ",
	Boolean = " ",
	Class = " ",
	Color = " ",
	Constant = " ",
	Constructor = " ",
	Enum = " ",
	EnumMember = " ",
	Event = " ",
	Field = " ",
	File = " ",
	Folder = " ",
	Function = " ",
	Interface = " ",
	Key = " ",
	Keyword = " ",
	Method = " ",
	Module = " ",
	Namespace = " ",
	Null = " ",
	Number = " ",
	Object = " ",
	Operator = " ",
	Package = " ",
	Property = " ",
	Snippet = "﬌ ",
	String = " ",
	Struct = " ",
	Text = " ",
	TypeParameter = " ",
	Unit = " ",
	Variable = " ",
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
