local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TagWatcher = {}
TagWatcher.__index = TagWatcher

function TagWatcher.new(fabric)
	local self = setmetatable({
		fabric = fabric;
		_tags = {};
		_deferredCreation = nil;
		_deferredRegistration = nil;
	}, TagWatcher)

	fabric:on("componentRegistered", function(staticComponent)
		if staticComponent.tag then
			if self._deferredRegistration == nil then
				self._deferredRegistration = {}

				local connection
				connection = self.fabric.Heartbeat:Connect(function()
					connection:Disconnect()

					for _, item in ipairs(self._deferredRegistration) do
						self:listenForTag(item.tag, item)
					end

					self._deferredRegistration = nil
				end)
			end

			table.insert(self._deferredRegistration, staticComponent)
		end
	end)

	return self
end

function TagWatcher:_deferCreation(staticComponent, instance, data)
	if self._deferredCreation == nil then
		self._deferredCreation = {}

		local connection
		connection = self.fabric.Heartbeat:Connect(function()
			connection:Disconnect()

			for _, item in ipairs(self._deferredCreation) do
				self.fabric:getOrCreateComponentByRef(item.staticComponent, item.instance):mergeBaseLayer(item.data)
			end

			self._deferredCreation = nil
		end)
	end

	table.insert(self._deferredCreation, {
		staticComponent = staticComponent;
		instance = instance;
		data = data;
	})
end

function TagWatcher:listenForTag(tag, staticComponent)
	self.fabric:debug("Creating components for tag", tag)
	assert(self._tags[tag] == nil, ("Tag %q is already in use!"):format(tag))
	self._tags[tag] = true

	local function addFromTag(instance)
		local data = {}

		if
			RunService:IsClient()
			and staticComponent.components
			and staticComponent.components.Replicated
		then
			-- Create component and let Replicated component subscribe
			self.fabric._collection:getOrCreateComponentByRef(staticComponent, instance)
		else
			if
				instance:FindFirstChild(staticComponent.name)
				and instance[staticComponent.name].ClassName == "ModuleScript"
			then
				data = require(instance[staticComponent.name])
			end

			self.fabric._collection:getOrCreateComponentByRef(staticComponent, instance)
			self:_deferCreation(staticComponent, instance, data)
		end
	end

	local function removeFromTag(instance)
		local component = self.fabric:getComponentByRef(staticComponent, instance)

		if component then
			component:fire("destroy")
		end
	end

	CollectionService:GetInstanceRemovedSignal(tag):Connect(removeFromTag)
	CollectionService:GetInstanceAddedSignal(tag):Connect(addFromTag)
	for _, instance in ipairs(CollectionService:GetTagged(tag)) do
		addFromTag(instance)
	end
end

return TagWatcher
