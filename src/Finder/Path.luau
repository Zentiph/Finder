--!strict

--- Path tools for working with Roblox Studio hierarchies.
--[=[
    @class Path
]=]
local Path = {}

--[=[
Join path segments into a single dot-separated path.
@param ... string The path segments to join.
@return string The joined path.
@within Path
]=]
function Path.join(...: string): string
	local parts = { ... }
	return table.concat(parts, ".")
end

--[=[
Split a path into segments.
@param path string The path to split.
@return { string } The path segments.
@within Path
]=]
function Path.split(path: string): { string }
	local segments = {}
	for segment in string.gmatch(path, "[^%.]+") do
		table.insert(segments, segment)
	end
	return segments
end

return Path
