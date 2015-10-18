LTpl = {}
LTpl.__index = LTpl

function LTpl.new(tplName)
	local self = setmetatable({}, LTpl)
	
	self.templateName = tplName
	self.expressions = {}
	
	self:init()
	return self
end

function LTpl.init(self)
	self:generateOutputName()
	self:parse()
end

function LTpl.generateOutputName(self)
	name = string.match(self.templateName, '%w+')
	self.outputName = name..'.html'
end

function LTpl.parse(self)
	self.fileContent = {}
	i = 1;
	
	for line in io.lines(self.templateName) do
		self.fileContent[i] = line
		i = i + 1
	end	
	
	self.count = i
end

function LTpl.set(self, variable, value)
	self.expressions[variable] = value;
end

function LTpl.getResult(self)
	self:setVariablesInTemplate()
	self:writeResult()
end

function LTpl.setVariablesInTemplate(self)
	for key, value in pairs(self.fileContent) do
		expression = string.match(value, '{{%w+}}')
		if expression ~= nil then
			variableName = string.match(expression, '%w+')
			variableValue = self.expressions[variableName]
			if  variableValue ~= nil then
				self.fileContent[key] = string.gsub(value, expression, variableValue)
			else
				self.fileContent[key] = string.gsub(value, expression, '')
			end
		end
	end
end

function LTpl.writeResult(self)
	outputFile = io.open(self.outputName, 'w')
	
	for key, value in pairs(self.fileContent) do
		outputFile:write(value..'\n')
	end
end