local Component = require(script.Parent.Component)
local Types = require(script.Parent.Types)
local isAllowedOnRef = require(script.Parent.isAllowedOnRef).isAllowedOnRef

local WEAK_KEYS_METATABLE = {
	__mode = "k"
}

local ComponentCollection = {}
ComponentCollection.__index = ComponentCollection

function ComponentCollection.new(fabric)
	return setmetatable({
		fabric = fabric;
		_componentsByName = {};
		_componentsByRef = {};
		_refComponents = {};
	}, ComponentCollection)
end

function ComponentCollection:register(componentDefinition, isHotReload)
	assert(Types.ComponentDefinition(componentDefinition))

	if not isHotReload then
		assert(self._componentsByName[componentDefinition.name] == nil, "A component with this name is already registered!")
	end

	self.fabric.Component[componentDefinition.name] = componentDefinition

	setmetatable(componentDefinition, Component)
	componentDefinition.__index = componentDefinition
	componentDefinition.__tostring = Component.__tostring
	componentDefinition.fabric = self.fabric

	componentDefinition.new = function()
		return setmetatable({}, componentDefinition)
	end

	self._componentsByName[componentDefinition.name] = componentDefinition
	self._componentsByRef[componentDefinition] = componentDefinition
end

function ComponentCollection:resolve(componentResolvable)
	return self._componentsByRef[componentResolvable]
		or self._componentsByName[componentResolvable]
end

function ComponentCollection:resolveOrError(componentResolvable)
	return self:resolve(componentResolvable) or error(
		("Cannot resolve component %s"):format(tostring(componentResolvable))
	)
end

function ComponentCollection:constructComponent(staticComponent, ref)
	assert(isAllowedOnRef(staticComponent, ref))

	local component = staticComponent.new()

	assert(
		getmetatable(component) == staticComponent,
		"Metatable of newly constructed component must be its static counterpart"
	)

	component.private = {}
	component._layers = {}
	component._layerOrder = {}
	component._reactsTo = setmetatable({}, WEAK_KEYS_METATABLE)
	component._componentScopeLayers = {}
	component._listeners = {}
	component.ref = ref
	component.fabric = self.fabric
	component._loading = false
	component._loaded = false

	self._refComponents[ref] = self._refComponents[ref] or {}
	self._refComponents[ref][staticComponent] = component

	component:on("destroy", function()
		self:deconstructComponent(component)
	end)

	if staticComponent.components then
		for name, data in pairs(staticComponent.components) do
			component:getOrCreateComponent(name):mergeBaseLayer(data)
		end
	end

	component:fire("initialize")

	return component
end

-- Need a way to hook into that and make sure components being removed is
-- identical to component having all data set to nil
-- Perhaps a component:destroy() method is necessary after all
function ComponentCollection:deconstructComponent(component)
	local staticComponent = getmetatable(component)

	self._refComponents[component.ref][staticComponent] = nil

	if next(self._refComponents[component.ref]) == nil then
		self._refComponents[component.ref] = nil
	end

	self:removeAllComponentsWithRef(component)

	component._listeners = nil
	component.ref = nil
	component._destroyed = true
	component._layers = nil
	component._layerOrder = nil
	component._reactsTo = nil

	for _, disconnect in pairs(component._componentScopeLayers) do
		disconnect()
	end

	component._componentScopeLayers = nil
end

function ComponentCollection:getComponentByRef(componentResolvable, ref)
	local staticComponent = self:resolveOrError(componentResolvable)

	return self._refComponents[ref] and self._refComponents[ref][staticComponent]
end

function ComponentCollection:getOrCreateComponentByRef(componentResolvable, ref)
	local component = self:getComponentByRef(componentResolvable, ref)

	if not component then
		component = self:constructComponent(self:resolveOrError(componentResolvable), ref)
	end

	return component
end

function ComponentCollection:removeAllComponentsWithRef(ref)
	if self._refComponents[ref] then
		for _staticComponent, component in pairs(self._refComponents[ref]) do
			component:fire("destroy")
		end
	end
end

return ComponentCollection
