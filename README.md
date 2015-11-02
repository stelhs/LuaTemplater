#LuaTemplater

Initialise templater
```
ltpl = LTpl.new '<template name>'
```

Assign block
```
ltpl:assign('<block_name>', {
    <variableName>: <variableValue>
})
```

Write result to file
```
ltpl:makeResult()
```

##Example
Template file (template.ltp)
```
<div style="border: solid 3px black; padding: 20px">
    <!-- START BLOCK : button -->
        <br>
        <br>
        <a href="{link}" style="border: solid 1px black">{name}</a>
    <!-- END BLOCK : button -->
</div>
<br>

    <!-- START BLOCK : button2 -->
        <br>
        <br>
        <a href="{link}" style="border: solid 1px black">{name}</a>
    <!-- END BLOCK : button2 -->
```

Code file
```
	require 'LuaTemplater'

	ltpl = LTpl.new 'template.ltp'
	ltpl:assign('button', {
		link = 'abc',
		name = 'bc'
	})

	ltpl:assign('button', {
		link = 'abca',
		name1 = 'aca'
	})

	ltpl:assign('button2', {
		link = '2abca',
		name = '2aca'
	})

	ltpl:assign('button2', {
		lin2k = '2ab2ca',
		name = 'ac2a'
	})


	ltpl:makeResult()
```

Result file (template.html)
```
<div style="border: solid 3px black; padding: 20px">
        <br>
        <br>
        <a href="abc" style="border: solid 1px black">bc</a>
        <br>
        <br>
        <a href="abca" style="border: solid 1px black"></a>
</div>
<br>

        <br>
        <br>
        <a href="2abca" style="border: solid 1px black">2aca</a>
        <br>
        <br>
        <a href="" style="border: solid 1px black">ac2a</a>
```