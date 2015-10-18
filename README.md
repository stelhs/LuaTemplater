#LuaTemplater

Initialise templater
```
ltpl = LTpl.new '<template name>'
```

Set variables
```
ltpl:set('<variableName>', '<variableValue>')
```

Write result to file
```
ltpl:getResult()
```

##Example
Template file (template.ltp)
```
	<div>
		<h1>Hello world</h1>
		<h2>{{name}}</h2>
		<h3>{{secondName}}</h3>
		<h4>{{age}}</h4>
	</div>
```

Code file
```
	require 'LuaTemplater'
	
	ltpl = LTpl.new 'template.ltp'
	ltpl:set('name', 'Vasua')
	ltpl:set('age', 20)
	ltpl:getResult()
```

Result file (template.html)
```
	<div>
		<h1>Hello world</h1>
		<h2>Vasua</h2>
		<h3></h3>
		<h4>20</h4>
	</div>
```