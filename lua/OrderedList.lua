-- a linked list that keeps itself in order (by default in descending order)

OrderedList = {}
OrderedList.__index = OrderedList


function OrderedList.create()
	local temp = {}
	setmetatable(temp, OrderedList)
	temp.size = 0
	temp.head = nil
	temp.tail = nil
	return temp
end

-- ====================================================

function OrderedList:add(val, pri)
	local newNode = {value = val, prev = nil, nxt = nil, priority = pri}
	self.size = self.size + 1
	if self.size == 1 then
		self.head = newNode
		self.tail = newNode
		newNode.nxt = newNode
		newNode.prev = newNode
	else
		local lookat = self.head
		while lookat.priority > pri do
			if lookat == self.tail then
				--insert at end
				self.tail.nxt = newNode
				self.head.prev = newNode
				newNode.nxt = self.head
				newNode.prev = self.tail
				self.tail = newNode
				--print("add " .. pri .. ":  " .. self:toString())
				return
			else
				lookat = lookat.nxt
			end
		end
		--insert in front of "lookat"
		if lookat == self.head then
			newNode.nxt = self.head
			newNode.prev = self.tail
			self.head.prev = newNode
			self.tail.nxt = newNode
			self.head = newNode
		else
			newNode.nxt = lookat
			newNode.prev = lookat.prev
			lookat.prev.nxt = newNode
			lookat.prev = newNode
		end
	end
	
	--print("add " .. pri .. ":  " .. self:toString())
end

-- ====================================================

function OrderedList:toString()
	if self.size == 0 then
		return
	end
	local s = "("
	local node = self.head
	while node ~= self.tail do
		s = s .. node.priority .. " "
		node = node.nxt
	end
	s = s .. node.priority .. " "
	return s .. ")"
end

-- ====================================================

function OrderedList:popFirst()
	if self.size == 0 then
		return nil
	end
	--print("remove")
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

function OrderedList:popLast()
	if self.size == 0 then
		return nil
	end
	self.size = self.size - 1
	if self.size == 0 then
		--just removed last node
		local temp = self.head
		self.head = nil
		self.tail = nil
		return temp.value
	else
		local temp = self.tail
		self.head.prev = self.tail.prev
		self.tail.prev.nxt = self.head
		self.tail = self.tail.prev
		return temp.value
	end
end

-- ====================================================