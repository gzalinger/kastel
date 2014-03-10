-- exactly what it sounds like

LinkedList = {}
LinkedList.__index = LinkedList


function LinkedList.create()
	local temp = {}
	setmetatable(temp, LinkedList)
	temp.size = 0
	temp.head = nil
	temp.tail = nil
	return temp
end

-- ====================================================

function LinkedList:add(val)
	local newNode = {value = val, prev = nil, nxt = nil}
	self.size = self.size + 1
	if self.size == 1 then
		self.head = newNode
		self.tail = newNode
		newNode.nxt = newNode
		newNode.prev = newNode
	else
		self.tail.nxt = newNode
		newNode.prev = self.tail
		self.head.prev = newNode
		newNode.nxt = self.head
		self.tail = newNode
	end
end

-- ====================================================

function LinkedList:addFirst(val)
	local newNode = {value = val, prev = nil, nxt = nil}
	self.size = self.size + 1
	if self.size == 1 then
		self.head = newNode
		self.tail = newNode
		newNode.nxt = newNode
		newNode.prev = newNode
	else
		self.tail.nxt = newNode
		self.head.prev = newNode
		newNode.nxt = self.head
		newNode.tail = self.tail
		self.head = newNode
	end
end

-- ====================================================

function LinkedList:popFirst()
	if self.size == 0 then
		return nil
	end
	self.size = self.size - 1
	if self.size == 0 then
		local temp = self.head
		self.head = nil
		self.tail = nil
		return temp.value
	else
		local temp = self.head
		self.head = self.head.nxt
		self.head.prev = self.tail
		self.tail.nxt = self.head
		return temp.value
	end
end

-- ====================================================

function LinkedList:values()
	--returns lua table with all values
	local values = {}
	if self.size == 0 then
		return values
	end
	table.insert(values, self.head.value)
	local node = self.head.nxt
	while node ~= self.head do
		table.insert(values, node.value)
		node = node.nxt
	end
	return values
end

-- ====================================================