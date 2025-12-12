--!strict

--- Perform operations on tree structures.
--[=[
	@class Tree
]=]
local Tree = {}

--[=[
Perform an operation on every child of an instance.
@param root Instance Root instance whose children are performed on.
@param callback (Instance) -> () The operation to apply to the searched Instances.
@within Tree
]=]
function Tree.ForEachChild(root: Instance, callback: (Instance) -> ()): ()
	for _, child in root:GetChildren() do
		callback(child)
	end
end

--[=[
Perform an operation on every descendant of an instance.
@param root Instance Root instance whose descendants are performed on.
@param callback (Instance) -> () The operation to apply to the searched Instances.
@within Tree
]=]
function Tree.ForEachDescendant(root: Instance, callback: (Instance) -> ()): ()
	for _, descendant in root:GetDescendants() do
		callback(descendant)
	end
end

--[=[
Clone all the children of an instance and place them within another.
@param source Instance Source instance whose children are cloned.
@param target Instance Target instance that receives the cloned children.
@param override boolean? Whether to override the old children of `target`. Defaults to false.
@within Tree
]=]
function Tree.CloneChildren(source: Instance, target: Instance, override: boolean?): ()
	if override then
		target:ClearAllChildren()
	end

	for _, child in source:GetChildren() do
		local clone = child:Clone()
		clone.Parent = target
	end
end

return Tree
