local function searchInSuperclasses(key, superclass_list)
    for _, class in ipairs(superclass_list) do
        local value = class[key]
        if value ~= nil then
            return value
        end
    end
end


function CreateClass(...)
    local class = {}

    class._superclasses = table.pack(...)

    if #class._superclasses == 0 then
        function class:new(object)
            object = object or {}
            object._class = self
            return setmetatable(object, class)
        end
    end

    class.__index = class

    return setmetatable(class, {__index = function (_, key)
        return searchInSuperclasses(key, class._superclasses)
    end})
end


BaseClass = CreateClass()
