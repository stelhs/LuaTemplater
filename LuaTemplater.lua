LTpl = {}
LTpl.__index = LTpl

function _getFileContent(fileName)
    local fileContent = ''

    for line in io.lines(fileName) do
        line = string.gsub(line, '//.*', '')
        fileContent = fileContent..line..'\n'
    end

    return fileContent
end

function LTpl.new(fileName)
    local self = setmetatable({}, LTpl)

    self.content = _getFileContent(fileName)
    self.blocks = {}

    self:init()

    return self
end

function LTpl.init(self)
    self:parseContent()
end

function LTpl.parseContent(self)
    self.content = self:findIncludeBlocks(self.content)
    self.content = self:findBlocks(self.content)
end

function LTpl.findIncludeBlocks(self, text)
    local startBlockRegexp = '<!%-%- *INCLUDE BLOCK *: *([%w\.]+) *%-%->'

    if text ~= nil then
        local fileName = string.match(text, startBlockRegexp) or ''
        local endBlockRegexp = '<!%-%- *END BLOCK *: *'..fileName..' *%-%->'

        if string.len(fileName) > 0 and string.match(text, endBlockRegexp) == nil then
            error ('Error parsing block: '..blockName)
        end

        while string.len(fileName) > 0 do
            text = self:findIncludeBlock(text, fileName)
            fileName = string.match(text, startBlockRegexp) or ''
        end
    end

    return text
end

function LTpl.findIncludeBlock(self, text, fileName)
    if text == nil or string.len(fileName) < 1 then
        return text
    end

    local blockRegexp = '<!%-%- *INCLUDE BLOCK *: *'..fileName..' *%-%->(.*)<!%-%- *END BLOCK *: *'..fileName..' *%-%->'
    local replaceBlockRegexp = '<!%-%- *INCLUDE BLOCK *: *'..fileName..' *%-%->.*<!%-%- *END BLOCK *: *'..fileName..' *%-%->'

    local data = string.match(text, blockRegexp);

    text = string.gsub(text, replaceBlockRegexp, LTpl:fillIncludeBlock(fileName, data))

    return text
end

function LTpl.fillIncludeBlock(self, fileName, data)
    local ltpl = LTpl.new(fileName)

    assignBlocks(ltpl, data)

    return ltpl:getContent()
end

function assignBlocks(ltpl, data)
    local startBlockDataRegexp = '<(%w+) *([ =%w]*)>'

    if data ~= nil then
        local blockName, blockData = string.match(data, startBlockDataRegexp)

        while blockName and blockData and string.len(blockName) > 0 and string.len(blockData) > 0 do
            local parsedData = parseData(blockData)
            ltpl:assign(blockName, parsedData)

            local innerData = string.match(data, '<'..blockName..' *'..blockData..'>(.*)</'..blockName..'>')
            assignBlocks(ltpl, innerData)

            data = string.gsub(data, '<'..blockName..' *'..blockData..'>'..innerData..'</'..blockName..'>', '')
            blockName, blockData = string.match(data, startBlockDataRegexp)
        end
    end

    return parsedData
end

function parseData(blockData)
    local data = {}

    local paramRegexp = '(%w+)=(%w+)'
    local key, value = string.match(blockData, paramRegexp)

    while key and value and string.len(key) > 0 and string.len(value) > 0 do
        data[key] = value
        blockData = string.gsub(blockData, key..'='..value, '')
        key, value = string.match(blockData, paramRegexp)
    end

    return data
end

function LTpl.findBlocks(self, text)
    local startBlockRegexp = '<!%-%- *START BLOCK *: *(%w+) *%-%->'

    if text ~= nil then
        local blockName = string.match(text, startBlockRegexp) or ''
        local endBlockRegexp = '<!%-%- *END BLOCK *: *'..blockName..' *%-%->'

        if string.len(blockName) > 0 and string.match(text, endBlockRegexp) == nil then
            error ('Error parsing block: '..blockName)
        end

        while string.len(blockName) > 0 do
            text = self:findBlock(text, blockName)
            blockName = string.match(text, startBlockRegexp) or ''
        end
    end

    return text
end

function LTpl.findBlock(self, text, blockName)
    if text == nil then
        return text
    end

    local blockRegexp = '<!%-%- *START BLOCK *: *'..blockName..' *%-%->(.*)<!%-%- *END BLOCK *: *'..blockName..' *%-%->'
    local replaceBlockRegexp = '<!%-%- *START BLOCK *: *'..blockName..' *%-%->.*<!%-%- *END BLOCK *: *'..blockName..' *%-%->'

    local block = string.match(text, blockRegexp);

    self.blocks[blockName] = self:findBlocks(block)

    text = string.gsub(text, replaceBlockRegexp, '<!--block_name: '..blockName..'-->')

    return text
end

function LTpl.assign(self, blockName, data)
    local blockRexexp = '<!%-%-block_name: '..blockName..'%-%->';
    local block = self:fillTemplate(blockName, data)

    self.content = string.gsub(self.content, blockRexexp, block..'<!--block_name: '..blockName..'-->');
end

function LTpl.fillTemplate(self, blockName, data)
    local block = self.blocks[blockName]

    if block ~= nil then
        for key, value in pairs(data) do
            block = string.gsub(block, '{'..key..'}', value)
        end
    end

    block = self:cleanBlock(block)

    return block
end

function LTpl.cleanBlock(self, block)
    local crearBlock = string.gsub(block, '{%w+}', '')

    return crearBlock
end

function LTpl.getContent(self)
    local result = string.gsub(self.content, '<!%-%-block_name: %w+%-%->', '')

    return result
end