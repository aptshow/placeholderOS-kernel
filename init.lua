--[[
   _____ _____________________   _________ ___ ___ ________  __      __  .___ _______  _________  
  /  _  \\______   \__    ___/  /   _____//   |   \\_____  \/  \    /  \ |   |\      \ \_   ___ \ 
 /  /_\  \|     ___/ |    |     \_____  \/    ~    \/   |   \   \/\/   / |   |/   |   \/    \  \/ 
/    |    \    |     |    |     /        \    Y    /    |    \        /  |   /    |    \     \____
\____|__  /____|     |____|    /_______  /\___|_  /\_______  /\__/\  /   |___\____|__  /\______  /
        \/                             \/       \/         \/      \/                \/        \/ 

    Copyright (c) 2025 Contributors to the Placeholder Kernel

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

    This is the entry point for the kernel.
    It loads the kernel and starts it.
    It also sets up the global metadata table.
    The metadata table contains information about the kernel, such as its name, version, author, and license.

]]

_G.metadata = {
    name = "placeholderOS",
    kernel = "placeholderKernel",
    version = "1.0.0",
    author = "APT SHOW INCORPORATED",
    license = "APGL"
}

local kernel = require("src.main")

kernel.run()