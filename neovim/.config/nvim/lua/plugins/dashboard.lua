return {
	opt = false,
	config = function()
		local db = require("dashboard")

		local logo = [[
███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗
████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║
██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║
██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║
██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║
╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝
]]

		logo = [[
                                                        *                  
     *                                                          *          
                                  *                  *        .--.         
      \/ \/  \/  \/                                        ./   /=*        
        \/     \/      *            *                ...  (_____)          
         \ ^ ^/                                       \ \_((^o^))-.     *  
         (o)(O)--)--------\.                           \   (   ) \  \._.   
         |    |  ||================((~~~~~~~~~~~~~~~~~))|   ( )   |     \  
          \__/             ,|        \. * * * * * * ./  (~~~~~~~~~~~)    \ 
   *        ||^||\.____./|| |          \___________/     ~||~~~~|~'\____/ *
            || ||     || || A            ||    ||          ||    |   jurcy 
     *      <> <>     <> <>          (___||____||_____)   ((~~~~~|   *     
]]

		logo = [[
    ███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗
    ████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║
    ██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║
    ██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║
    ██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║
    ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝
                               _                         
                           ,--.\`-. __                   
                         _,.`. \:/,"  `-._               
                     ,-*" _,.-;-*`-.+"*._ )              
                    ( ,."* ,-" / `.  \.  `.              
                   ,"   ,;"  ,"\../\  \:   \             
                  (   ,"/   / \.,' :   ))  /             
                   \  |/   / \.,'  /  // ,'              
                    \_)\ ,' \.,'  (  / )/                
                        `  \._,'   `"                    
                           \../                          
                           \../                          
                 ~        ~\../           ~~             
          ~~          ~~   \../   ~~   ~      ~~         
     ~~    ~   ~~  __...---\../-...__ ~~~     ~~         
       ~~~~  ~_,--'        \../      `--.__ ~~    ~~     
   ~~~  __,--'              `"             `--.__   ~~~  
~~  ,--'                                         `--.    
   '------......______             ______......------` ~~
 ~~~   ~    ~~      ~ `````---"""""  ~~   ~     ~~       
        ~~~~    ~~  ~~~~       ~~~~~~  ~ ~~   ~~ ~~~  ~  
     ~~   ~   ~~~     ~~~ ~         ~~       ~~   SSt    
              ~        ~~       ~~~       ~              
]]
		local lines = {}
		for line in logo:gmatch("[^\n]+") do
			table.insert(lines, line)
		end

		db.custom_header = lines
		db.preview_file_height = 11
		db.preview_file_width = 70

		db.custom_center = {
			{
				icon = "  ",
				desc = "Recent sessions                         ",
				shortcut = "SPC s l",
				action = "SessionLoad",
			},
			{
				icon = "  ",
				desc = "Find recent files                       ",
				action = "Telescope oldfiles",
				shortcut = "SPC f r",
			},
			{
				icon = "  ",
				desc = "Find files                              ",
				action = "Telescope find_files find_command=rg,--hidden,--files",
				shortcut = "SPC f f",
			},
			{
				icon = "  ",
				desc = "File browser                            ",
				action = "Telescope file_browser",
				shortcut = "SPC f b",
			},
			{
				icon = "  ",
				desc = "Find word                               ",
				action = "Telescope live_grep",
				shortcut = "SPC f w",
			},
			{
				icon = "  ",
				desc = "Load new theme                          ",
				action = "Telescope colorscheme",
				shortcut = "SPC h t",
			},
		}
		db.custom_footer = { "", "🎉 If I'm using Neovim, then I must've really lost my mind." }
		db.session_directory = "/home/amaanq/.config/nvim/session"

		vim.g.dashboard_custom_header = lines

		vim.g.dashboard_custom_shortcut = {
			["last_session"] = "SPC s l",
			["find_history"] = "SPC f r",
			["find_file"] = "SPC spc",
			["new_file"] = "SPC f n",
			["change_colorscheme"] = "SPC h c",
			["find_word"] = "SPC f g",
			["book_marks"] = "SPC f b",
		}
	end,
}
