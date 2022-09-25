-------------------------------------------------
-- AMAANQ'S NEOVIM CONFIGURATION
-- Neovim website: https://neovim.io/
-------------------------------------------------

require("amaanq.settings");
require("amaanq.autocmd");
require("amaanq.plugins");
require("amaanq.keybinds");

---Pretty print lua table
function _G.dump(...)
    local objects = vim.tbl_map(vim.inspect, { ... })
    print(unpack(objects))
end
