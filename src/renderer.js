function renderAst(ast) {
	function render(node) {
		if (node.type === 'ConditionalExpression') {
			return '(' + render(node.test) + '?' +  render(node.consequent) + ':' + render(node.alternate) + ')';
		}
		else if (node.type === 'BinaryExpression') {
			return '(' + render(node.left) + node.operator + render(node.right) + ')';
		}
		else if (node.type === 'MemberExpression') {
			if (node.computed) {
				return render(node.object) + '[' + node.property.name + ']';
			}
			else {
				return render(node.object) + '.' + node.property.name;
			}
		}
		else if (node.type === 'SequenceExpression') {
			var buffer = '';
			for (var i = 0, n = node.expressions.length; i < n; ++i) {
				if (i > 0) {
					buffer += ',';
				}
				buffer += render(node.expressions[i]);
			}
			return buffer;
		}
		else if (node.type === 'Literal') {
			return node.value;
		}
		else if (node.type === 'Identifier') {
			return node.name;
		}

		throw "Unknown AST node type: " + node.type;
	}

	return render(ast);
}