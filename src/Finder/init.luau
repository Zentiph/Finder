--!strict

--- Finder resolves Instances by dot-separated paths with optional caching and logging.
--[=[
	@class Finder
]=]
local Finder = {}

Finder.Search = require(script.Search)

local function resolvePath(root: Instance, path: string, useWait: boolean, timeout: number?): Instance?
	local current = root

	for segment in string.gmatch(path, "[^%.]+") do
		local new

		if useWait then
			if timeout then
				new = current:WaitForChild(segment, timeout)
			else
				new = current:WaitForChild(segment)
			end
		else
			new = current:FindFirstChild(segment)
		end

		if not new then
			return nil
		end

		current = new
	end

	return current
end

--- Finds an Instance by path using `FindFirstChild` for each segment.
--[=[
	@within Finder
	@param root Instance The Instance to start the search from.
	@param path string Dot-separated path, e.g. `"Workspace.Map.Spawn"`.
	@return Instance? The found Instance or `nil` if any segment is missing.
]=]
function Finder.Find(root: Instance, path: string): Instance?
	return resolvePath(root, path, false)
end

--- Finds an Instance by path, waiting for each segment with `WaitForChild`.
--[=[
	@within Finder
	@param root Instance The Instance to start the search from.
	@param path string Dot-separated path, e.g. `"ReplicatedStorage.Config.Flag"`.
	@param timeout number? Timeout in seconds for each `WaitForChild` call.
	@return Instance? The found Instance or `nil` if any segment times out or is missing.
]=]
function Finder.FindWithWait(root: Instance, path: string, timeout: number?): Instance?
	return resolvePath(root, path, true, timeout)
end

return Finder
