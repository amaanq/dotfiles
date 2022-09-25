local A = vim.api
local option = A.nvim_buf_get_option

local M = {}

---@class Opts
---@field non_modifiable boolean: Whether to delete non-modifiable buffers

local function notify(msg)
    vim.notify("Buffers: " .. msg)
end

---Create a scratch + unlisted buffers and also hides the [No Name] buffer
local function scratch(win)
    A.nvim_win_set_buf(win or 0, A.nvim_create_buf(false, true))
end

---Remove all buffers except the current one
---@param opts Opts
function M.only(opts)
    opts = opts or {}

    local cur = A.nvim_get_current_buf()

    local deleted, modified = 0, 0
    for _, buf in ipairs(A.nvim_list_bufs()) do
        -- If the iter buffer is modified one, then don't do anything
        if option(buf, "modified") then
            -- iter is not equal to current buffer
            -- iter is modifiable or del_non_modifiable == true
            -- `modifiable` check is needed as it will prevent closing file tree ie. NERD_tree
            modified = modified + 1
        elseif buf ~= cur and (option(buf, "modifiable") or opts.non_modifiable) then
            A.nvim_buf_delete(buf, { force = true })
            deleted = deleted + 1
        end
    end

    notify(("%s deleted, %s modified"):format(deleted, modified))
end

---Remove all the buffers
---@param opts Opts
function M.clear(opts)
    opts = opts or {}

    local deleted, modified = 0, 0
    for _, buf in ipairs(A.nvim_list_bufs()) do
        -- If the iter buffer is modified one, then don't do anything
        if option(buf, "modified") then
            -- iter is not equal to current buffer
            -- iter is modifiable or del_non_modifiable == true
            -- `modifiable` check is needed as it will prevent closing file tree ie. NERD_tree
            modified = modified + 1
        elseif (option(buf, "modifiable") or opts.non_modifiable) and option(buf, "buflisted") then
            A.nvim_buf_delete(buf, { force = true })
            deleted = deleted + 1
        end
    end

    -- If current buffer is not scratch then and only create scratch buffer
    local cur_buf = A.nvim_get_current_buf()
    if option(cur_buf, "buflisted") then
        scratch()
        A.nvim_buf_delete(cur_buf, { force = true })
    end

    notify(("%s deleted, %s modified"):format(deleted, modified))
end

---Nicely delete the current buffer (lua port of vim-bbye)
function M.delete()
    local cur_buf = A.nvim_get_current_buf()

    -- If buffer is not listed that means it is a scratch buffer
    -- In that case just return silently
    if not option(cur_buf, "buflisted") then
        return
    end

    if not A.nvim_buf_is_loaded(cur_buf) then
        return notify(("Invalid buffer - %s"):format(cur_buf))
    end

    if option(cur_buf, "modified") then
        return notify("Current buffer is modified. Please save it before delete!")
    end

    local wins = A.nvim_list_wins()
    for i = #wins, 1, -1 do
        local win = wins[i]

        -- If window is valid and the current window holds the current buffer
        if A.nvim_win_is_valid(win) and A.nvim_win_get_buf(win) == cur_buf then
            A.nvim_set_current_win(win)

            local next_buf = vim.fn.bufnr("#")
            if next_buf > 0 and A.nvim_buf_is_loaded(next_buf) then
                A.nvim_set_current_buf(next_buf)
            else
                pcall(A.nvim_command, "bprevious")
            end

            -- If all the windows holds the current buffer then create a scratch buffer on top of the current buffer
            if A.nvim_get_current_buf() == cur_buf then
                scratch(win)
            end
        end
    end

    -- TODO: I don't know what this does
    -- " Because tabbars and other appearing/disappearing windows change
    -- " the window numbers, find where we were manually:
    -- let back = filter(range(1, winnr("$")), "getwinvar(v:val, 'bbye_back')")[0]
    -- if back | exe back . "wincmd w" | unlet w:bbye_back | endif

    -- When moving buffers is done, delete the original/current buffer
    if cur_buf ~= A.nvim_get_current_buf() then
        A.nvim_buf_delete(cur_buf, { force = true })
    end

    notify(("#%s deleted"):format(cur_buf))
end

return M;
