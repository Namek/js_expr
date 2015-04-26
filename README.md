# js_expr
Parser for simple JavaScript expressions based on [PEG.js](http://pegjs.org/).

# Build the parser
1. `npm install`
2. `gulp build`
3. `dist/js_expr.js` is the output

# Use the parser

The parser builds in nodejs' `module` manner. It exports `function parse(expr)` which returns an [AST](http://en.wikipedia.org/wiki/Abstract_syntax_tree).

The AST can be rendered back to JS code, look into [src/renderer.js](src/renderer.js).
