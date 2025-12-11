--!strict

--- Search for instances under certain conditions.
--[=[
	@class Search
]=]
local Search = {}

----------------------------------
-- matching (predicate) methods --
----------------------------------

local function waitForMatching(
	root: Instance,
	initial: () -> Instance?,
	connectSignal: (
		root: Instance,
		predicate: (Instance) -> boolean,
		setResult: (Instance) -> ()
	) -> RBXScriptConnection,
	predicate: (Instance) -> boolean,
	timeout: number?,
	description: string
): Instance?
	local timeoutNumber = timeout or math.huge
	local warningPrinted = false
	local start = os.clock()

	local found = initial()
	if found then
		return found
	end

	local result: Instance? = nil
	local connection = connectSignal(root, predicate, function(inst: Instance)
		result = inst
	end)

	while not result and os.clock() - start < timeoutNumber do
		if not root.Parent then
			break
		end

		if not timeout and not warningPrinted then
			warn(`[Finder.Search]: Infinite yield possible on '{description}'`)
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
function Search.WaitForChildMatching(root: Instance, predicate: (Instance) -> boolean, timeout: number?)
	return waitForMatching(root, function()
		return Search.FindFirstChildMatching(root, predicate)
	end, function(r, pred, setResult)
		return r.ChildAdded:Connect(function(child)
			if pred(child) then
				setResult(child)
			end
		end)
	end, predicate, timeout, `Finder.Search.WaitForChildMatching({root.Name})`)
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
	return waitForMatching(root, function()
		return Search.FindFirstDescendantMatching(root, predicate)
	end, function(r, pred, setResult)
		return r.DescendantAdded:Connect(function(descendant)
			if pred(descendant) then
				setResult(descendant)
			end
		end)
	end, predicate, timeout, `Finder.Search.WaitForDescendantMatching({root.Name})`)
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

	for _, child in root:GetChildren() do
		if predicate(child) then
			table.insert(results, child)
		end
	end

	return results
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

local function getRandomItem<T>(tab: { T }): T?
	local count = #tab
	if count == 0 then
		return nil
	end
	return tab[math.random(1, count)]
end

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
