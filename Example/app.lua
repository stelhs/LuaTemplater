require 'LuaTemplater'

function _getFileContent(fileName)
    local fileContent = ''

    for line in io.lines(fileName) do
        fileContent = fileContent..line..'\n'
    end

    return fileContent
end

function main ()
    local ltpl = LTpl.new( _getFileContent('Templates/main.html'))
    print(ltpl:getContent())
end

main ()