require 'LuaTemplater'

function main()
    local ltpl = LTpl.new('template.html', {
        src = 'sources/'
    }, false)

    ltpl:assign('but', {
        class='btn btn-primary';
        name='HW'
    })

    print(ltpl:getContent())
end

main()

