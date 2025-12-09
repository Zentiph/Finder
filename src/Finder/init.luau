--!strict

--- Finder resolves Instances by dot-separated paths with optional caching and logging.
--[=[
	@class Finder
    @author zen :3
]=]
local Finder = {}

Finder.Search = require(script.Search)

export type LogLevel = "print" | "warn" | "error" | "none"

--- Log level constants used by Finder.
--[=[
	@within Finder
	@field Print "print" Logs missing segments with `print`.
	@field Warn "warn" Logs missing segments with `warn`.
	@field Error "error" Throws when a segment is missing.
	@field None "none" Disables missing-segment logging.
]=]
Finder.LogLevel = {
	Print = "print",
	Warn = "warn",
	Error = "error",
	None = "none",
}

--- Default log level used when none is provided to lookup methods.
--[=[
	@within Finder
	@field DefaultLogLevel string
]=]
Finder.DefaultLogLevel = Finder.LogLevel.Warn

local function log(message: string, level: string)
	if level == Finder.LogLevel.Error then
		error(message, 2)
	elseif level == Finder.LogLevel.Warn then
		warn(message)
	elseif level == Finder.LogLevel.Print then
		print(message)
	end
end

local function resolvePath(root: Instance, path: string, level: string, useWait: boolean, timeout: number?): Instance?
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
			log(`[Finder]: Could not find "{segment}" in path "{path}" from root {root:GetFullName()}`, level)
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
	@param logLevel LogLevel? Overrides `Finder.DefaultLogLevel` for this lookup.
	@return Instance? The found Instance or `nil` if any segment is missing.
]=]
function Finder.Find(root: Instance, path: string, logLevel: LogLevel?): Instance?
	local level = logLevel or Finder.DefaultLogLevel
	return resolvePath(root, path, level, false)
end

--- Finds an Instance by path, waiting for each segment with `WaitForChild`.
--[=[
	@within Finder
	@param root Instance The Instance to start the search from.
	@param path string Dot-separated path, e.g. `"ReplicatedStorage.Config.Flag"`.
	@param timeout number? Timeout in seconds for each `WaitForChild` call.
	@param logLevel LogLevel? Overrides `Finder.DefaultLogLevel` for this lookup.
	@return Instance? The found Instance or `nil` if any segment times out or is missing.
]=]
function Finder.FindWithWait(root: Instance, path: string, timeout: number?, logLevel: LogLevel?): Instance?
	local level = logLevel or Finder.DefaultLogLevel
	return resolvePath(root, path, level, true, timeout)
end

return Finder
