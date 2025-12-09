local Search = {}

function Search.FindFirstChildWithTag(root: Instance, tag: string): Instance?
	local CollectionService = game:GetService("CollectionService")

	for _, child in root:GetChildren() do
		if CollectionService:HasTag(child, tag) then
			return child
		end
	end

	return nil
end

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

function Search.FindFirstDescendantWithTag(root: Instance, tag: string): Instance?
	local CollectionService = game:GetService("CollectionService")

	for _, descendant in root:GetDescendants() do
		if CollectionService:HasTag(descendant, tag) then
			return descendant
		end
	end

	return nil
end

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
