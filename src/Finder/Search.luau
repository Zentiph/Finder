--!strict

--- Search for instances under certain conditions.
--[=[
	@class Search
]=]
local Search = {}

----------------------------------
-- matching (predicate) methods --
----------------------------------

local function instanceExists(instance: Instance): boolean
	return instance.Parent ~= nil or instance == game
end

local function getRandomItem<T>(tab: { T }): T?
	local count = #tab
	if count == 0 then
		return nil
	end
	return tab[math.random(1, count)]
end

local function waitForMatch(
	root: Instance,
	initial: () -> Instance?,
	subscribe: (setResult: (Instance) -> ()) -> RBXScriptConnection,
	timeout: number?,
	warningLabel: string
): Instance?
	local timeoutNumber = timeout or math.huge
	local warningPrinted = false
	local start = os.clock()

	local found = initial()
	if found then
		return found
	end

	local result: Instance? = nil
	local connection = subscribe(function(instance: Instance)
		result = instance
	end)

	while not result and os.clock() - start < timeoutNumber do
		if not root.Parent then
			break
		end

		if not timeout and not warningPrinted then
			warn(`[Finder.Search]: Infinite yield possible on '{warningLabel}'`)
			warningPrinted = true
		end

		task.wait()
	end

	if connection then
		connection:Disconnect()
	end

	return result
end

--[=[
Finds the first direct child of `root` that matches the given condition.
@param root Instance Root instance whose children are searched.
@param predicate (Instance) -> boolean The predicate to apply to the searched Instances.
@return Instance? Child matching the condition, or nil if none are found.
@within Search
]=]
function Search.FindFirstChildMatching(root: Instance, predicate: (Instance) -> boolean): Instance?
	if not instanceExists(root) then
		return nil
	end

	for _, child in root:GetChildren() do
		if predicate(child) then
			return child
		end
	end

	return nil
end

--[=[
Walks up the ancestry of `root` and returns the first ancestor that matches the given condition.
@param root Instance Root instance whose ancestors are searched.
@param predicate (Instance) -> boolean The predicate to apply to the searched Instances.
@return Instance? Ancestor matching the condition, or nil if none are found.
@within Search
]=]
function Search.FindFirstAncestorMatching(root: Instance, predicate: (Instance) -> boolean): Instance?
	if not instanceExists(root) then
		return nil
	end

	local ancestor = root.Parent
	while ancestor do
		if predicate(ancestor) then
			return ancestor
		end
		ancestor = ancestor.Parent
	end

	return nil
end

--[=[
Searches all descendants of `root` for the first instance matching the given condition.
@param root Instance Root instance whose descendants are searched.
@param predicate (Instance) -> boolean The predicate to apply to the searched Instances.
@return Instance? Descendant matching the condition, or nil if none are found.
@within Search
]=]
function Search.FindFirstDescendantMatching(root: Instance, predicate: (Instance) -> boolean): Instance?
	if not instanceExists(root) then
		return nil
	end

	for _, descendant in root:GetDescendants() do
		if predicate(descendant) then
			return descendant
		end
	end

	return nil
end

--[=[
Yields until a child of `root` matches the given condition or the optional timeout elapses.
Prints an infinite yield warning when no timeout is provided.
@param root Instance Instance whose children are watched.
@param predicate (Instance) -> boolean The predicate to apply to the searched instances.
@param timeout number? Maximum seconds to wait; defaults to infinite.
@return Instance? Child matching the condition, or nil if the timeout is reached first.
@within Search
]=]
function Search.WaitForChildMatching(root: Instance, predicate: (Instance) -> boolean, timeout: number?): Instance?
	return waitForMatch(root, function()
		return Search.FindFirstChildMatching(root, predicate)
	end, function(setResult)
		return root.ChildAdded:Connect(function(child)
			if predicate(child) then
				setResult(child)
			end
		end)
	end, timeout, `Finder.Search.WaitForChildMatching({root:GetFullName()}, <predicate>)`)
end

--[=[
Yields until a descendant of `root` matches the given condition or the optional timeout elapses.
Prints an infinite yield warning when no timeout is provided.
@param root Instance Instance whose descendants are watched.
@param predicate (Instance) -> boolean The predicate to apply to the searched instances.
@param timeout number? Maximum seconds to wait; defaults to infinite.
@return Instance? Descendant matching the condition, or nil if the timeout is reached first.
@within Search
]=]
function Search.WaitForDescendantMatching(root: Instance, predicate: (Instance) -> boolean, timeout: number?): Instance?
	return waitForMatch(root, function()
		return Search.FindFirstDescendantMatching(root, predicate)
	end, function(setResult)
		return root.DescendantAdded:Connect(function(descendant)
			if predicate(descendant) then
				setResult(descendant)
			end
		end)
	end, timeout, `Finder.Search.WaitForDescendantMatching({root.Name}, <predicate>)`)
end

--[=[
Get all the children of `root` that match the given condition.
@param root Instance Root instance whose children are searched.
@param predicate (Instance) -> boolean The predicate to apply to the searched instances.
@return { Instance } Children matching the condition.
@within Search
]=]
function Search.GetChildrenMatching(root: Instance, predicate: (Instance) -> boolean): { Instance }
	local results = {}

	if not instanceExists(root) then
		return results
	end

	for _, child in root:GetChildren() do
		if predicate(child) then
			table.insert(results, child)
		end
	end

	return results
end

--[=[
Get an iterator over the children of `root` matching the given condition.
@param root Instance Root instance whose children are searched.
@param predicate (Instance) -> boolean The predicate to apply to the searched instances.
@return () -> Instance? An iterator over the matching children.
@within Search
]=]
function Search.IterChildrenMatching(root: Instance, predicate: (Instance) -> boolean): () -> Instance?
	local children = root:GetChildren()
	local index = 0

	return function()
		while true do
			index += 1
			local instance = children[index]

			if not instance then
				return nil
			end
			if predicate(instance) then
				return instance
			end
		end
	end
end

--[=[
Get an iterator over the descendants of `root` matching the given condition.
@param root Instance Root instance whose descendants are searched.
@param predicate (Instance) -> boolean The predicate to apply to the searched instances.
@return () -> Instance? An iterator over the matching descendants.
@within Search
]=]
function Search.IterDescendantsMatching(root: Instance, predicate: (Instance) -> boolean): () -> Instance?
	local descendants = root:GetDescendants()
	local index = 0

	return function()
		while true do
			index += 1
			local instance = descendants[index]

			if not instance then
				return nil
			end
			if predicate(instance) then
				return instance
			end
		end
	end
end

--[=[
Get all the descendants of `root` that match the given condition.
@param root Instance Root instance whose descendants are searched.
@param predicate (Instance) -> boolean The predicate to apply to the searched instances.
@return { Instance } Descendants matching the condition.
@within Search
]=]
function Search.GetDescendantsMatching(root: Instance, predicate: (Instance) -> boolean): { Instance }
	local results = {}

	if not instanceExists(root) then
		return results
	end

	for _, descendant in root:GetDescendants() do
		if predicate(descendant) then
			table.insert(results, descendant)
		end
	end

	return results
end

-------------------
-- randomness!!! --
-------------------

--[=[
Returns a random child of `root` matching the given condition.
@param root Instance Root instance whose children are searched.
@param predicate (Instance) -> boolean The predicate to apply to the searched instances.
@return Instance? The randomly chosen child matching the condition, or nil if there are none.
@within Search
]=]
function Search.GetRandomChildMatching(root: Instance, predicate: (Instance) -> boolean): Instance?
	return getRandomItem(Search.GetChildrenMatching(root, predicate))
end

--[=[
Returns a random descendant of `root` matching the given condition.
@param root Instance Root instance whose descendants are searched.
@param predicate (Instance) -> boolean The predicate to apply to the searched instances.
@return Instance? The randomly chosen descendant matching the condition, or nil if there are none.
@within Search
]=]
function Search.GetRandomDescendantMatching(root: Instance, predicate: (Instance) -> boolean): Instance?
	return getRandomItem(Search.GetDescendantsMatching(root, predicate))
end

----------------------------------------------------
-- descendant versions of FindFirstChild_ methods --
----------------------------------------------------

--[=[
Find the first descendant which `:IsA(className)`.
@param root Instance Root instance whose descendants are searched.
@param className string The class type to find.
@return Instance? The first descendant of the class type or nil if there are none.
@within Search
]=]
function Search.FindFirstDescendantWhichIsA(root: Instance, className: string): Instance?
	return Search.FindFirstDescendantMatching(root, function(instance: Instance): boolean
		return instance:IsA(className)
	end)
end

--[=[
Find the first descendant whose class name matches the one provided.
@param root Instance Root instance whose descendants are searched.
@param className string The class name to find.
@return Instance? The first descendant with the class name or nil if there are none.
@within Search
]=]
function Search.FindFirstDescendantOfClass(root: Instance, className: string): Instance?
	return Search.FindFirstDescendantMatching(root, function(instance: Instance): boolean
		return instance.ClassName == className
	end)
end

return Search
