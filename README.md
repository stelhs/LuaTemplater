#LuaTemplater

Initialise templater
```
ltpl = LTpl.new '<template name>' '<root variables>' '<clean spaces> = false'
```

Assign block
```
ltpl:assign('<block_name>', {
    <variableName>: <variableValue>
})
```

Get result
```
ltpl:getContent()
```