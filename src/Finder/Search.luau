--!strict

--- Search for instances under certain conditions.
--[=[
	@class Search
]=]
local Search = {}

--[=[
Finds the first direct child of `root` that has the given tag.
@param root Instance Root instance whose children are searched.
@param tag string Tag to look for.
@return Instance? Child with the tag, or nil if none are found.
@within Search
]=]
function Search.FindFirstChildWithTag(root: Instance, tag: string): Instance?
	local CollectionService = game:GetService("CollectionService")

	for _, child in root:GetChildren() do
		if CollectionService:HasTag(child, tag) then
			return child
		end
	end

	return nil
end

--[=[
Walks up the ancestry of `root` and returns the first ancestor with the tag.
@param root Instance Instance whose ancestors are inspected.
@param tag string Tag to look for.
@return Instance? Ancestor with the tag, or nil if none are found.
@within Search
]=]
function Search.FindFirstAncestorWithTag(root: Instance, tag: string): Instance?
	local CollectionService = game:GetService("CollectionService")

	local current = root.Parent
	while current do
		if CollectionService:HasTag(current, tag) then
			return current
		end
		current = current.Parent
	end

	return nil
end

--[=[
Searches all descendants of `root` for the first instance with the tag.
@param root Instance Root instance whose descendants are searched.
@param tag string Tag to look for.
@return Instance? Descendant with the tag, or nil if none are found.
@within Search
]=]
function Search.FindFirstDescendantWithTag(root: Instance, tag: string): Instance?
	local CollectionService = game:GetService("CollectionService")

	for _, descendant in root:GetDescendants() do
		if CollectionService:HasTag(descendant, tag) then
			return descendant
		end
	end

	return nil
end

--[=[
Yields until a child of `root` with the tag appears or the optional timeout elapses.
Prints an infinite yield warning when no timeout is provided.
@param root Instance Instance whose children are watched.
@param tag string Tag to wait for.
@param timeout number? Maximum seconds to wait; defaults to infinite.
@return Instance? Child with the tag, or nil if the timeout is reached first.
@within Search
]=]
function Search.WaitForChildWithTag(root: Instance, tag: string, timeout: number?): Instance?
	local CollectionService = game:GetService("CollectionService")
	local timeoutNumber = timeout or math.huge
	local warningPrinted = false

	local start = os.clock()

	local found = Search.FindFirstChildWithTag(root, tag)
	if found then
		return found
	end

	local result: Instance? = nil
	local connection
	connection = root.ChildAdded:Connect(function(child: Instance)
		if CollectionService:HasTag(child, tag) then
			result = child
		end
	end)

	while not result and os.clock() - start < timeoutNumber do
		if not timeout and not warningPrinted then
			warn(
				`[Finder.Search]: Infinite yield possible on 'Finder.Search.WaitForChildWithTag({root.Name}, "{tag}")'`
			)
			warningPrinted = true
		end

		task.wait()
	end

	if connection then
		connection:Disconnect()
	end

	return result
end

return Search
