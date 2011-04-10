grammar LetaGrammar;

options {
  output=AST;
}

tokens {
  LETA;
  STMT;
  TESTCASE;
  WHEN;
  VERIFY;
  SET;
  FACTCOMPOSITE;
  CONJUNCTION;
  DISJUNCTION;
  FACT;
  FACTEXT;
  FACTUNARY;
  FACTBINARY;
  FACTNARY;
  TERMCOMPOSITE;
  FORMULA;
  TERM;
  TERMINSTANCE;
  TERMWITHASSOCIATION;
  COMPLEMENT;
  NULL;
  LITERAL;
  QUANTIFIER;
  FORMULAEXPRESSION;
  FORMULAEXPRESSIONCOMPOSITE;
  FORMULAITEM;
  OPERATOR;
  SET;
  SUBSET;
  SEPARATOR;
  AND;
  OR;
  PACKAGE;
}

@header {
  package leta.core.grammar;
  
  import leta.core.model.*;
}

@lexer::header {
  package leta.core.grammar;
  
  import leta.core.model.*;
}

@members {
  private boolean foundErrors = false;

  public boolean hasFoundErrors() {
    return this.foundErrors;
  }
  
  public String getErrorMessage(RecognitionException e, String[] tokenNames) {
    foundErrors = true;

    String msg = super.getErrorMessage(e, tokenNames);
    return msg;
  }  
}

leta
  : testPackage? testCase+ 
    -> ^(LETA testPackage? testCase+)
  ;

testCase
  : 'Test' ID verifyClause whenClause setClause?
    -> ^(TESTCASE ID setClause? verifyClause whenClause)
  ;

verifyClause
  : 'Verify' factComposite
    -> ^(VERIFY factComposite)
  ;

whenClause
  : 'When' factComposite
    -> ^(WHEN factComposite)
  ;

setClause
  : 'Set' '{' set '}'
    -> ^(SET set)
  ;

factComposite
  : (f=fact | fo=formula) (op=logicalOperator fc=factComposite)?
    -> {op != null && op.value.equals("And") && f != null}? ^('And' $f $fc)
    -> {op != null && op.value.equals("Or") && f != null}? ^('Or' $f $fc)
    -> {op != null && op.value.equals("And") && fo != null}? ^('And' $fo $fc)
    -> {op != null && op.value.equals("Or") && fo != null}? ^('Or' $fo $fc)
    -> {f != null}? ^(FACTCOMPOSITE $f)
    -> ^(FACTCOMPOSITE $fo)
  | '(' fc1=factComposite ')' (op=logicalOperator fc2=factComposite)?
    -> {op != null && op.value.equals("And")}? ^('And' $fc1 $fc2)
    -> {op != null && op.value.equals("Or")}? ^('Or' $fc1 $fc2)
    -> ^(FACTCOMPOSITE $fc1)
  ;

logicalOperator returns [String value]
  : 'And'
    { $value = "And"; }
  | 'Or'
    { $value = "Or"; }
  ;

fact
  : tc=termComposite c=complement (tc2=termComposite fe=factExt?)?
    -> ^(FACT $tc $c ($tc2 $fe?)?)
  ;

factExt
  : ',' termComposite factExt?
    -> ^(FACTEXT SEPARATOR termComposite factExt?)
  | complement (termComposite factExt?)?
    -> ^(FACTEXT complement (termComposite factExt?)?)
  ;

termComposite
  : quantifier? (t=term | ti=termInstance | twa=termWithAssociation)
    -> {t != null}? ^(TERMCOMPOSITE quantifier? term)
    -> {ti != null}? ^(TERMCOMPOSITE quantifier? termInstance)
    -> ^(TERMCOMPOSITE quantifier? termWithAssociation)
  ;

term
  : ID
    -> ^(TERM ID)
  ;

termInstance
  : term relationalOperator? literal
    -> ^(TERMINSTANCE term relationalOperator? literal)
  ;

termWithAssociation
  : term relationalOperator? '@' INT
    -> ^(TERMWITHASSOCIATION term relationalOperator? INT)
  ;
  
quantifier
  : 'each'
    -> ^(QUANTIFIER 'each')
  | 'some'
    -> ^(QUANTIFIER 'some')
  | 'atLeastOne'
    -> ^(QUANTIFIER 'atLeastOne')
  | 'atLeast' INT
    -> ^(QUANTIFIER 'atLeast' INT)
  | 'atMostOne'
    -> ^(QUANTIFIER 'atMostOne')
  | 'atMost' INT
    -> ^(QUANTIFIER 'atMost' INT)
  | 'exactlyOne'
    -> ^(QUANTIFIER 'exactlyOne')
  | 'exactly' INT
    -> ^(QUANTIFIER 'exactly' INT)
  | 'moreThanOne'
    -> ^(QUANTIFIER 'moreThanOne')
  | 'atLeastAndAtMost' i1=INT i2=INT
    -> ^(QUANTIFIER 'atLeastAndAtMost' $i1 $i2)
  ;

complement
  : ID
    -> ^(COMPLEMENT ID)
  ;

formula
  : formulaItem '=' formulaExpression
    -> ^(FORMULA formulaItem formulaExpression)
  ;

formulaExpression
  : formulaItem (mathOperator formulaExpression)?
    -> ^(FORMULAEXPRESSION formulaItem (mathOperator formulaExpression)?)
  | '(' formulaExpression ')' (mathOperator formulaExpression)? 
    -> ^(FORMULAEXPRESSION formulaExpression (mathOperator formulaExpression)?)
  ;

formulaItem
  : (term | termInstance | termWithAssociation)
    -> ^(FORMULAITEM term? termInstance? termWithAssociation?)
  ;

mathOperator
  : '+'
    -> ^(OPERATOR '+')
  | '-'
    -> ^(OPERATOR '-')
  | '/'
    -> ^(OPERATOR '/')
  | '*'
    -> ^(OPERATOR '*')
  | '%'
    -> ^(OPERATOR '%')
  | '**'
    -> ^(OPERATOR '**')
  ;

relationalOperator
  : '>'
    -> ^(OPERATOR '>')
  | '<'
    -> ^(OPERATOR '<')
  | '>='
    -> ^(OPERATOR '>=')
  | '<='
    -> ^(OPERATOR '<=')
  | '!='
    -> ^(OPERATOR '!=')
  ;

set
  : '{' subSet '}' (',' set)?
    -> ^(SET subSet set?)
  ;

subSet
  : literal (',' subSet)?
    -> ^(SUBSET literal subSet?)
  ;

literal
  : STRING
    -> ^(LITERAL STRING)
  | FLOAT
    -> ^(LITERAL FLOAT)
  | MINUS_FLOAT
    -> ^(LITERAL MINUS_FLOAT)
  | INT
    -> ^(LITERAL INT)
  | MINUS_INT
    -> ^(LITERAL MINUS_INT)
  | 'null'
    -> ^(LITERAL NULL)
  ;

testPackage
  : 'Package' PACKAGE_ID
    -> ^(PACKAGE PACKAGE_ID)
  ;

ID
  : ('a'..'z' | 'A'..'Z' | '_') ('a'..'z' | 'A'..'Z' | '_' | '0'..'9')*
  ;

fragment
DIGIT
  : '0'..'9'
  ;

INT
  : DIGIT+
  ;

MINUS_INT
  : '-' DIGIT+
  ;

FLOAT
  : DIGIT+ '\.' DIGIT*
  ;

MINUS_FLOAT
  : '-' DIGIT+ '\.' DIGIT*
  ;

STRING
  : '"' (~('"' | '\\'))* '"'
  ;
  
PACKAGE_ID
  : ('a'..'z' | 'A'..'Z') ('a'..'z' | 'A'..'Z' | '_' | '.' | '0'..'9')* ('a'..'z' | 'A'..'Z' | '0'..'9')
  ;

COMMENT
  : '/*' (options {greedy=false;} : .)* '*/' {$channel = HIDDEN;}
  ;

LINE_COMMENT
  : '//' (~'\n')* '\n' {$channel = HIDDEN;}
  ;

WS
  : (' ' | '\t' | '\n' | '\r')+ { $channel=HIDDEN; }
  ;