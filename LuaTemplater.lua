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
    self.data = {}
end

function LTpl.generateOutputName(self)
    name = string.match(self.templateName, '%w+')
    self.outputName = name .. '.html'
end

function LTpl.parse(self)
    self.fileContent = {}
    i = 1

    for line in io.lines(self.templateName) do
        self.fileContent[i] = line
        i = i + 1
    end

    self.count = i
    self:parseContent()
end

function LTpl.parseContent(self)
    i = 1
    j = 1

    self.parsedContent = {}
    self.blocks = {}

    while i < self.count do
        blockName = string.match(self.fileContent[i], '<!%-%- *START BLOCK *: *(%w*) *%-%->')

        if blockName ~= nil then
            endResult = nil
            startIndex = i
            block = {}

            while endResult == nil and i < self.count do
                endResult = string.match(self.fileContent[i], '<!%-%- *END BLOCK *: *' .. blockName .. ' *%-%->')

                if endResult == nil and i ~= startIndex then
                    block[i - startIndex + 1] = self.fileContent[i]
                end

                i = i + 1
            end

            self.blocks[blockName] = block;
            self.parsedContent[j] = '<!--block_' .. blockName .. '-->'

            j = j + 1
        else
            self.parsedContent[j] = self.fileContent[i]

            j = j + 1
            i = i + 1
        end
    end
end

function LTpl.assign(self, blockName, data)
    if self.data[blockName] == nil then
        self.data[blockName] = {}
        self.data[blockName].nextIndex = 2
        self.data[blockName].blocksData = {}

        self.data[blockName].blocksData[1] = data
    else
        index = self.data[blockName].nextIndex

        self.data[blockName].nextIndex = index + 1
        self.data[blockName].blocksData[index] = data
    end
end

function LTpl.makeResult(self)
    result = {}
    i = 1

    for key, value in pairs(self.parsedContent) do
        name = string.match(value, '<!%-%-block_(.*)%-%->')

        if name ~= nil then
            if self.data[name] ~= nill then
                blockCount = self.data[name].nextIndex
                j = 1
                while j < blockCount do
                    for key, value in pairs(LTpl:fillTemplate(self.blocks[name], self.data[name].blocksData[j])) do
                        result[i] = value
                        i = i + 1
                    end
                    j = j + 1
                end
            end
        else
            result[i] = value
            i = i + 1
        end
    end

    self:writeResult(result)
end

function LTpl.fillTemplate(self, block, data)
    processedBlock = {};

    for key, value in pairs(block) do
        processedBlock[key] = value
        variableName = string.match(value, '{(%w+)}')

        while variableName ~= nil do
            variableValue = data[variableName]

            if variableValue ~= nil then
                processedBlock[key] = string.gsub(processedBlock[key], '{' .. variableName .. '}', variableValue)
            else
                processedBlock[key] = string.gsub(processedBlock[key], '{' .. variableName .. '}', '')
            end

            variableName = string.match(processedBlock[key], '{(%w+)}')
        end
    end

    return processedBlock
end

function LTpl.writeResult(self, result)
    outputFile = io.open(self.outputName, 'w')

    for key, value in pairs(result) do
        outputFile:write(value..'\n')
    end
end