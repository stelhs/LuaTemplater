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
    self.content = string.gsub(self.content, '//.*%z', '')
    self.content = self:findBlocks(self.content)
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