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

function LTpl.new(fileName, rootBlocks)
    local self = setmetatable({}, LTpl)

    self.content = _getFileContent(fileName)
    self.blocks = {}
    self.rootBlocks = rootBlocks

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
    local startBlockRegexp = '<!%-%- *START INSERT *: *([%w%.]+) *%-%->'

    if text ~= nil then
        local fileName = string.match(text, startBlockRegexp) or ''
        local endBlockRegexp = '<!%-%- *END INSERT *: *'..fileName..' *%-%->'

        if string.len(fileName) > 0 and string.match(text, endBlockRegexp) == nil then
            error ('Error parsing block: '..fileName)
        end

        while string.len(fileName) > 0 do
            text = self:findIncludeBlock(text, fileName)
            fileName = string.match(text, startBlockRegexp) or ''
        end
    end

    return text
end

function LTpl.findIncludeBlock(self, text, fileName)
    if text == nil then
        return text
    end

    local blockRegexp = '<!%-%- *START INSERT *: *'..fileName..' *%-%->(.*)<!%-%- *END INSERT *: *'..fileName..' *%-%->'
    local replaceBlockRegexp = '<!%-%- *START INSERT *: *'..fileName..' *%-%->.*<!%-%- *END INSERT *: *'..fileName..' *%-%->'

    local block = string.match(text, blockRegexp);

    text = string.gsub(text, replaceBlockRegexp, LTpl:parseData(block, fileName))

    return text
end

function LTpl.parseData(self, block, fileName)
    local root = {}

    local variableRegexp = '<([^>]*)>'
    local blockRegexp = '!%-%- *START ASSIGN *: *([%w]+) *%-%-'
    local variable = string.match(block, variableRegexp)
    local blockName = nil

    while blockName == nil and variable ~= nil do
        local valueRegexp = '< *'..variable..' *>([^<>]*)</ *'..variable..' *>'
        local value = string.match(block, valueRegexp)

        local valueReplaceRegexp = '< *'..variable..' *>'..value..'</ *'..variable..' *>'
        root[variable] = value

        block = string.gsub(block, valueReplaceRegexp, '')

        variable = string.match(block, variableRegexp)
        blockName = string.match(variable or '', blockRegexp)
    end

    local blockLtpl = LTpl.new(fileName, root)

    if blockName ~= nil then
        local blockDataRegexp = '<!%-%- *START ASSIGN *: *'..blockName..' *%-%->(.*)<!%-%- *END ASSIGN *: *'..blockName..' *%-%->'
        LTpl:parseBlock(blockLtpl, string.match(block, blockDataRegexp), blockName)
    end

    return blockLtpl:getContent()
end

function LTpl.parseBlock(self, ltpl, block, name)
    if block == nil then
        return
    end

    local root = {}

    local variableRegexp = '<([^>]*)>'
    local blockRegexp = '!%-%- *START ASSIGN *: *([%w]+) *%-%-'
    local variable = string.match(block, variableRegexp)
    local blockName = nil

    while blockName == nil and variable ~= nil do
        local valueRegexp = '< *'..variable..' *>([^<>]*)</ *'..variable..' *>'
        local value = string.match(block, valueRegexp)

        local valueReplaceRegexp = '< *'..variable..' *>'..value..'</ *'..variable..' *>'
        root[variable] = value

        block = string.gsub(block, valueReplaceRegexp, '')

        variable = string.match(block, variableRegexp)
        blockName = string.match(variable or '', blockRegexp)
    end

    ltpl:assign(name, root)

    if blockName ~= nil then
        local blockDataRegexp = '<!%-%- *START ASSIGN *: *'..blockName..' *%-%->(.*)<!%-%- *END ASSIGN *: *'..blockName..' *%-%->'
        LTpl:parseBlock(ltpl, string.match(block, blockDataRegexp), blockName)
    end
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

    return block
end

function LTpl.assignRootBlocks(self, text, rootBlocks)
    if rootBlocks ~= nil then
        for key, value in pairs(rootBlocks) do
            text = string.gsub(text, '{'..key..'}', value)
        end
    end

    return text
end

function LTpl.clean(self, text)
    local text = string.gsub(text, '{%w+}', '')
    text = string.gsub(text, '<!%-%-block_name: %w+%-%->', '')
    text = string.gsub(text, '/%*[^*/]*%*/', '')

    text = LTpl:cleanLinesAndSpaces(text)

    return text
end

function LTpl.cleanLinesAndSpaces(self, text)
    text = string.gsub(text, '\n', '')
    text = string.gsub(text, '%s+', ' ')

    return text
end

function LTpl.getContent(self)
    local result = LTpl:assignRootBlocks(self.content, self.rootBlocks)
    result = LTpl:clean(result)

    return result
end