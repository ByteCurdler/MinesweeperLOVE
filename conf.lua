function love.conf(t)
    t.version = "11.3"
    t.window.icon = "minesweeper-love.png"
	t.releases = {
		title = "Minesweeper",              -- The project title (string)
		package = "minesweeper-love",            -- The project command and package name (string)
		loveVersion = "11.3",        -- The project LÖVE version
		version = "v0.0.1",            -- The project version
		author = "ILikePython256",             -- Your name (string)
		email = nil,              -- Your email (string)
		description = "A Minesweeper clone made with LÖVE",        -- The project description (string)
		homepage = nil,           -- The project homepage (string)
		identifier = nil,         -- The project Uniform Type Identifier (string)
		excludeFileList = {},     -- File patterns to exclude. (string list)
		releaseDirectory = "release",   -- Where to store the project releases (string)
	}
end
