/*
 * JavaScript Value Expression Grammar
 * ==================
 *
 */

{
  function extractOptional(optional, index) {
    return optional ? optional[index] : null;
  }

  function extractList(list, index) {
    var result = new Array(list.length), i;

    for (i = 0; i < list.length; i++) {
      result[i] = list[i][index];
    }

    return result;
  }

  function buildList(first, rest, index) {
    return [first].concat(extractList(rest, index));
  }

  function buildTree(first, rest, builder) {
    var result = first, i;

    for (i = 0; i < rest.length; i++) {
      result = builder(result, rest[i]);
    }

    return result;
  }

  function buildBinaryExpression(first, rest) {
    return buildTree(first, rest, function(result, element) {
      return {
        type:     "BinaryExpression",
        operator: element[1],
        left:     result,
        right:    element[3]
      };
    });
  }

  function optionalList(value) {
    return value !== null ? value : [];
  }
}

Start
  = _ program:Program _ { return program; }

/* ----- A.1 Lexical Grammar ----- */

SourceCharacter
  = .

WhiteSpace "whitespace"
  = "\t"
  / "\v"
  / "\f"
  / " "
  / "\u00A0"
  / "\uFEFF"

Identifier
  = !CommonReservedWord name:IdentifierName { return name; }

IdentifierName "identifier"
  = first:IdentifierStart rest:IdentifierPart* {
      return {
        type: "Identifier",
        name: first + rest.join("")
      };
    }

IdentifierStart
  = "$"
  / "_"

IdentifierPart
  = IdentifierStart
  / "\u200C"
  / "\u200D"

CommonReservedWord
  = ThisToken
  / NullLiteral
  / BooleanLiteral

Literal
  = NullLiteral
  / BooleanLiteral
  / NumericLiteral
  / StringLiteral

NullLiteral
  = NullToken { return { type: "Literal", value: null }; }

BooleanLiteral
  = TrueToken  { return { type: "Literal", value: true  }; }
  / FalseToken { return { type: "Literal", value: false }; }

/*
 * The "!(IdentifierStart / DecimalDigit)" predicate is not part of the official
 * grammar.
 */
NumericLiteral "number"
  = literal:DecimalLiteral !(IdentifierStart / DecimalDigit) {
      return literal;
    }

DecimalLiteral
  = DecimalIntegerLiteral "." DecimalDigit* {
      return { type: "Literal", value: parseFloat(text()) };
    }
  / "." DecimalDigit+ {
      return { type: "Literal", value: parseFloat(text()) };
    }
  / DecimalIntegerLiteral {
      return { type: "Literal", value: parseFloat(text()) };
    }

DecimalIntegerLiteral
  = "0"
  / NonZeroDigit DecimalDigit*

DecimalDigit
  = [0-9]

NonZeroDigit
  = [1-9]

StringLiteral "string"
  = '"' chars:DoubleStringCharacter* '"' {
      return { type: "Literal", value: chars.join("") };
    }
  / "'" chars:SingleStringCharacter* "'" {
      return { type: "Literal", value: chars.join("") };
    }

DoubleStringCharacter
  = !('"' / "\\") SourceCharacter { return text(); }
  / "\\" sequence:EscapeSequence { return sequence; }

SingleStringCharacter
  = !("'" / "\\") SourceCharacter { return text(); }
  / "\\" sequence:EscapeSequence { return sequence; }

EscapeSequence
  = CharacterEscapeSequence
  / "0" !DecimalDigit { return "\0"; }

CharacterEscapeSequence
  = SingleEscapeCharacter
  / NonEscapeCharacter

SingleEscapeCharacter
  = "'"
  / '"'
  / "\\"
  / "b"  { return "\b";   }
  / "f"  { return "\f";   }
  / "n"  { return "\n";   }
  / "r"  { return "\r";   }
  / "t"  { return "\t";   }
  / "v"  { return "\x0B"; }   // IE does not recognize "\v".

NonEscapeCharacter
  = !EscapeCharacter SourceCharacter { return text(); }

EscapeCharacter
  = SingleEscapeCharacter
  / DecimalDigit

/* Tokens */

FalseToken      = "false"      !IdentifierPart
InstanceofToken = "instanceof" !IdentifierPart
InToken         = "in"         !IdentifierPart
NullToken       = "null"       !IdentifierPart
ThisToken       = "this"       !IdentifierPart
TrueToken       = "true"       !IdentifierPart

/* Skipped */
_
  = (WhiteSpace)*


/* ----- A.2 Expressions ----- */

PrimaryExpression
  = ThisToken { return { type: "ThisExpression" }; }
  / Identifier
  / Literal
  / "(" _ expression:Expression _ ")" { return expression; }

MemberExpression
  = first:(
        PrimaryExpression
    )
    rest:(
        _ "[" _ property:Expression _ "]" {
          return { property: property, computed: true };
        }
      / _ "." _ property:IdentifierName {
          return { property: property, computed: false };
        }
    )*
    {
      return buildTree(first, rest, function(result, element) {
        return {
          type:     "MemberExpression",
          object:   result,
          property: element.property,
          computed: element.computed
        };
      });
    }

LeftHandSideExpression
  = MemberExpression

MultiplicativeExpression
  = first:LeftHandSideExpression
    rest:(_ MultiplicativeOperator _ LeftHandSideExpression)*
    { return buildBinaryExpression(first, rest); }

MultiplicativeOperator
  = $("*" !"=")
  / $("/" !"=")
  / $("%" !"=")

AdditiveExpression
  = first:MultiplicativeExpression
    rest:(_ AdditiveOperator _ MultiplicativeExpression)*
    { return buildBinaryExpression(first, rest); }

AdditiveOperator
  = $("+" ![+=])
  / $("-" ![-=])

RelationalExpression
  = first:AdditiveExpression
    rest:(_ RelationalOperator _ AdditiveExpression)*
    { return buildBinaryExpression(first, rest); }

RelationalOperator
  = "<="
  / ">="
  / $("<" !"<")
  / $(">" !">")
  / $InstanceofToken
  / $InToken

EqualityExpression
  = first:RelationalExpression
    rest:(_ EqualityOperator _ RelationalExpression)*
    { return buildBinaryExpression(first, rest); }

EqualityOperator
  = "==="
  / "!=="
  / "=="
  / "!="

LogicalANDExpression
  = first:EqualityExpression
    rest:(_ LogicalANDOperator _ EqualityExpression)*
    { return buildBinaryExpression(first, rest); }

LogicalANDOperator
  = "&&"

LogicalORExpression
  = first:LogicalANDExpression
    rest:(_ LogicalOROperator _ LogicalANDExpression)*
    { return buildBinaryExpression(first, rest); }

LogicalOROperator
  = "||"

ConditionalExpression
  = test:LogicalORExpression _
    "?" _ consequent:ConditionalExpression _
    ":" _ alternate:ConditionalExpression
    {
      return {
        type:       "ConditionalExpression",
        test:       test,
        consequent: consequent,
        alternate:  alternate
      };
    }
  / LogicalORExpression

Expression
  = first:ConditionalExpression rest:(_ "," _ ConditionalExpression)* {
      return rest.length > 0
        ? { type: "SequenceExpression", expressions: buildList(first, rest, 3) }
        : first;
    }

/* ----- A.3 Statements ----- */

Statement
  = ExpressionStatement

ExpressionStatement
  = !("{") expression:Expression {
      return {
        type:       "ExpressionStatement",
        expression: expression
      };
    }

/* ----- A.4 Functions and Programs ----- */

Program
  = body:SourceElements? {
      return {
        type: "Program",
        body: optionalList(body)
      };
    }

SourceElements
  = first:SourceElement rest:(_ SourceElement)* {
      return buildList(first, rest, 1);
    }

SourceElement
  = Statement
