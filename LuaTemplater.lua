LTpl = {}
LTpl.__index = LTpl

local singleLineCommentRegexp = '//.-\\n'
local multiLineCommentRegexp = '/%*.-%*/'

local function _find(element, destination)
    for elem in string.gmatch(destination, '.') do
        if elem == element then
            return true
        end
    end

    return false
end

local function _escapeSymbols(line)
    local escapedLine = ''
    local symbolsToEscape = '-'

    for symbol in string.gmatch(line, '.') do
        if _find(symbol, symbolsToEscape) then
            escapedLine = escapedLine .. '%' .. symbol
        else
            escapedLine = escapedLine .. symbol
        end
    end

    return escapedLine
end

local startInsertBlockRegexp = '<!%-%- *START INSERT *: *([%w%.]+) *%-%->'
local function _getEndInsertBlockRegexp(fileName)
    return '<!%-%- *END INSERT *: *' .. _escapeSymbols(fileName) .. ' *%-%->'
end

local function _getInsetBlockDataRegexp(fileName)
    return '<!%-%- *START INSERT *: *' .. _escapeSymbols(fileName) .. ' *%-%->(.-)<!%-%- *END INSERT *: *' .. _escapeSymbols(fileName) .. ' *%-%->'
end

local function _getInsertBlockReplaceRegexp(fileName)
    return '<!%-%- *START INSERT *: *' .. _escapeSymbols(fileName) .. ' *%-%->.-<!%-%- *END INSERT *: *' .. _escapeSymbols(fileName) .. ' *%-%->'
end

local variableRegexp = '<([^>]*)>'
local function _getValueRegexp(variableName)
    return '< *' .. _escapeSymbols(variableName) .. ' *>(.-)</ *' .. _escapeSymbols(variableName) .. ' *>'
end

local function _getVariableReplaceRegexp(variableName, value)
    return '< *' .. _escapeSymbols(variableName) .. ' *>' .. _escapeSymbols(value) .. '</ *' .. _escapeSymbols(variableName) .. ' *>'
end

local startAssignBlockRegexp = '<!%-%- *START ASSIGN *: *([%w]+) *%-%->'
local function _getAssignBlockRegexp(blockName)
    return '<!%-%- *START ASSIGN *: *' .. _escapeSymbols(blockName) .. ' *%-%->(.-)<!%-%- *END ASSIGN *: *' .. _escapeSymbols(blockName) .. ' *%-%->'
end

local startBlockRegexp = '<!%-%- *START BLOCK *: *(%w+) *%-%->'
local function _getEndBlockRegexp(blockName)
    return '<!%-%- *END BLOCK *: *' .. _escapeSymbols(blockName) .. ' *%-%->'
end

local function _getBlockDataRegexp(blockName)
    return '<!%-%- *START BLOCK *: *' .. _escapeSymbols(blockName) .. ' *%-%->(.-)<!%-%- *END BLOCK *: *' .. _escapeSymbols(blockName) .. ' *%-%->'
end

local function _getBlockReplaceRegexp(blockName)
    return '<!%-%- *START BLOCK *: *' .. _escapeSymbols(blockName) .. ' *%-%->.-<!%-%- *END BLOCK *: *' .. _escapeSymbols(blockName) .. ' *%-%->'
end

local function _getBlockCommentRegexp(blockName)
    return '<!%-%-block_name: ' .. _escapeSymbols(blockName) .. '%-%->'
end

local function _getFileContent(fileName)
    local fileContent = ''

    for line in io.lines(fileName) do
        fileContent = fileContent .. line .. '\\n'
    end

    return fileContent
end

local function _checkErrorEndingBlock(blockName, regexp, text)
    if string.len(blockName) > 0 and string.match(text, regexp) == nil then
        error('Error parsing block: ' .. blockName)
    end
end

local function _removeData(text, regexp)
    return string.gsub(text, regexp, '')
end

local function _parseBlock(self, text, blockName)
    if text == nil then
        return text
    end

    local blockData = string.match(text, _getBlockDataRegexp(blockName))

    self.blocks[blockName] = _parseBlocks(self, blockData)

    text = string.gsub(text, _getBlockReplaceRegexp(blockName), '<!--block_name: ' .. blockName .. '-->')

    return text
end

function _parseBlocks(self, text)
    if text ~= nil then
        local blockName = string.match(text, startBlockRegexp) or ''

        _checkErrorEndingBlock(blockName, _getEndBlockRegexp(blockName), text)

        while string.len(blockName) > 0 do
            text = _parseBlock(self, text, blockName)
            blockName = string.match(text, startBlockRegexp) or ''
        end
    end

    return text
end

local function _getVariables(block)
    local variables = {}

    local variableName = string.match(block, variableRegexp)
    local assignBlockName = nil
    local isStartBlockLine = nil

    while assignBlockName == nil and isStartBlockLine == nil and variableName ~= nil do
        local value = string.match(block, _getValueRegexp(variableName))

        variables[variableName] = value

        block = _removeData(block, _getVariableReplaceRegexp(variableName, value))

        variableName = string.match(block, variableRegexp)
        assignBlockName = string.match('<' .. (variableName or '') .. '>', startAssignBlockRegexp)
        isStartBlockLine = string.match('<' .. (variableName or '') .. '>', startBlockRegexp) or string.match('<' .. (variableName or '') .. '>', startInsertBlockRegexp)
    end

    return variables, assignBlockName
end

local function _fillAssignBlock(blockLtpl, block, blockName)
    if blockName ~= nil then
        local blockData = string.match(block, _getAssignBlockRegexp(blockName))
        local variables, assignBlockName = _getVariables(blockData)
        blockLtpl:assign(blockName, variables)
        _fillAssignBlock(blockLtpl, blockData, assignBlockName)
    end
end

local function _fillInsertBlock(block, fileName)
    local rootVariables, assignBlockName = _getVariables(block)

    local blockLtpl = LTpl.new(fileName, rootVariables, false, false)

    _fillAssignBlock(blockLtpl, block, assignBlockName)

    return blockLtpl:getContent()
end

local function _parseInsertBlock(text, fileName)
    if text == nil then
        return text
    end

    local block = string.match(text, _getInsetBlockDataRegexp(fileName));

    return string.gsub(text, _getInsertBlockReplaceRegexp(fileName), _fillInsertBlock(block, fileName))
end

local function _parseInsertBlocks(text)
    if text ~= nill then
        local fileName = string.match(text, startInsertBlockRegexp) or ''

        _checkErrorEndingBlock(fileName, _getEndInsertBlockRegexp(fileName), text)

        while string.len(fileName) > 0 do
            text = _parseInsertBlock(text, fileName)
            fileName = string.match(text, startInsertBlockRegexp) or ''
            _checkErrorEndingBlock(fileName, _getEndInsertBlockRegexp(fileName), text)
        end
    end

    return text
end

local function _parseContent(self)
    self.content = _parseInsertBlocks(self.content)
    self.content = _parseBlocks(self, self.content)
end

local function _cleanComments(self)
    self.content = _removeData(self.content, singleLineCommentRegexp)
    self.content = _removeData(self.content, multiLineCommentRegexp)
end

local function _init(self)
    self.blocks = {}
    _cleanComments(self)
    _parseContent(self)
end

function LTpl.new(fileName, rootBlocks, cleanFile, cleanUnusedVariables)
    local self = setmetatable({}, LTpl)

    self.content = _getFileContent(fileName)
    self.rootBlocks = rootBlocks
    self.cleanFile = cleanFile == nil and false or cleanFile
    self.cleanUnusedVariables = cleanUnusedVariables == nil and true or cleanUnusedVariables

    _init(self)

    return self
end

local function _fillTemplate(self, blockName, data)
    local block = self.blocks[blockName]

    if block ~= nil then
        for key, value in pairs(data) do
            block = string.gsub(block, '{' .. key .. '}', value)
        end
    end

    return block
end

function LTpl.assign(self, blockName, data)
    local block = _fillTemplate(self, blockName, data)

    self.content = string.gsub(self.content, _getBlockCommentRegexp(blockName), block .. '<!--block_name: ' .. blockName .. '-->');
end

local function _cleanBlockComment(self)
    self.content = string.gsub(self.content, '<!%-%-block_name: %w+%-%->', '')
end

local function _cleanUnusedVariables(self)
    if self.cleanUnusedVariables == true then
        self.content = string.gsub(self.content, '{%w+}', '')
    end
end

local function _cleandDoubleSpaces(self)
    if self.cleanFile == true then
        self.content = string.gsub(self.content, '\\n', '')
        self.content = string.gsub(self.content, '%s+', ' ')
    else
        self.content = string.gsub(self.content, '\\n', '\n')
    end
end

local function _clean(self)
    _cleanBlockComment(self)
    _cleanUnusedVariables(self)
    _cleandDoubleSpaces(self)
end

local function _assignRootBlocks(self)
    if self.rootBlocks ~= nil then
        for key, value in pairs(self.rootBlocks) do
            self.content = string.gsub(self.content, '{' .. key .. '}', value)
        end
    end

    return text
end

function LTpl.getContent(self)
    _assignRootBlocks(self)
    _clean(self)

    return self.content
end