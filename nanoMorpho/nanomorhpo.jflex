/*
   Authors : Ingvar Hrafn Þorsteinsson and Hilmir Berg Halldórsson

   What is JFlex ?
    JFlex is a lexical analyzer generator that takes an input specification with a set of regular expressions and corresponding actions.
    It generates a program (a lexer) that reads input, matches the input against the regular expressions in the spec file,
    and runs the corresponding action if a regular expression matched. Lexers usually are the first front-end step in compilers,
    matching keywords, comments, operators, etc, and generating an input token stream for parsers. 
    They can also be used for many other purposes.

   About This Project.
   For this project, we will use JFlex to create a scanner for the language NanoMorpho.
*/

import java.io.*;
import java.util.Vector;
import java.util.HashMap;

// %% means the start of declarations
%%

// Tells JFlex that the generated class is public
%public
// Tells JFlex to generate a class named NanoMorpho
%class NanoMorpho
/*
 defines the set of characters the scanner will work on. 
 For scanning text files %unicode should always be used
*/
%unicode
/*
JFlex has built-in support for the Java extension BYacc/J,
BYacc/J expects a function int yylex() in the parser class that returns each next token. 
Semantic values are expected in a field yylval of type parserval where parser is the name of the generated parser class.
*/
%byaccj 
// Switches line counting on (the current line number can be accessed via the variable yyline)
%line
// Switches column counting on (the current column is accessed via yycolumn)
%column 

/* 
   Everything inside %{ %} will be inserted in the generated class, here you can
   define your tokens, lexemes, how the scanner works and more
*/
%{
    /*
        Definitions of our tokens.
        Note : token values should be high so they do not conflict with ASCII values
    */
    final static int ERROR = -1;
    // By default 0 is end of file but we want to have it as a constant
    final static int ENDOFFILE = 0;
    final static int VAR = 1001;
    final static int LITERAL = 1002;
    final static int IF = 1003;
    final static int ELSIF = 1004;
    final static int ELSE = 1005;
    final static int WHILE = 1006;
    final static int RETURN = 1007;
    final static int NAME = 1008;
    final static int OPNAME = 1009;

    /*
        Variables that will contain tokens, lexemes and their position in the text (line, column) as they are recognized.
        We will need to store the current token and lexeme, also the next token and lexeme
        due to some ambiguity that would appear if we would only track one token and lexeme at a time. 
    */
    private static int currentToken;
    private static int nextToken;
    private static String currentLexeme;
    private static String nextLexeme;
    private static int currentLine;
    private static int nextLine;
    private static int currentColumn;
    private static int nextColumn;

    private static NanoMorpho lexer;
    private static ProgramGenerator progGenerator = new ProgramGenerator();
    
    /*
        The symbol table consists of the following two variables.
        Where string is the name of the variable which is also the key
        and the integer value is the location of that variable.
    */
    private static int varCount;
    private static HashMap<String,Integer> varTable;

    public static void main( String[] args ) throws Exception
    {
        lexer = new NanoMorpho(new FileReader(args[0]));
        lexer.init();
        Object[] generatedCode = lexer.beginParse();
        progGenerator.generateProgram(args[0],generatedCode);
        /*
            // For debugging purposes 
            while(lexer.getToken() != ENDOFFILE )
            {
                System.out.println("(line,column): ("+(lexer.getLine() + 1) +","+(lexer.getColumn()+ 1) +") | "+lexer.getToken()+": \'"+lexer.getLexeme()+"\'");
                lexer.advance();
            }
        */
    }

    /*
        Usage : init()
          For : nothing
        After : fetches the first token, lexeme, line and column and calls the advance function
       Throws : can throw an Exception not sure which one, since we specified that we are using byaccj
                JFlex implements the functions that byaccj has such as yylex() which could throw Exceptions  
    */
    private void init() throws Exception
    {
        nextToken = lexer.yylex();
        nextLexeme = yytext();
        nextLine = yyline;
        nextColumn = yycolumn;
        lexer.advance();
    }

    /*
        Usage : advance()
          For : nothing
        After : sets the current token, lexeme, line and column values and fetches the next token only
                if we have not reached end of file
    */
    private int advance() throws Exception
    {
        currentToken = nextToken;
        currentLexeme = nextLexeme;
        currentLine = nextLine;
        currentColumn = nextColumn;
    
        if(currentToken != ENDOFFILE)
        {
            nextToken = lexer.yylex();
            nextLexeme = yytext();
            nextLine = yyline;
            nextColumn = yycolumn;
        }

        return currentToken;
    }

    //--------------------------- GETTERS : START ----------------------------------
    private int getToken() 
    {
        return currentToken;
    }

    private int getNextToken()
    {
        return nextToken;
    }

    private String getLexeme()
    {
        return currentLexeme;
    }

    private String getNextLexeme()
    {
        return nextLexeme;
    }

    private int getLine()
    {
        return currentLine;
    }

    private int getNextLine()
    {
        return nextLine;
    }

    private int getColumn()
    {
        return currentColumn;
    }

    private int getNextColumn()
    {
        return nextColumn;
    }

    /*
       Adds a new variable to the symbol table.
       Throws Error if the variable already exists.
    */
    private static void addVar( String name ) throws Exception
    {
        if( varTable.get(name) != null )
        {
            throw new Error("Variable "+name+" already exists, near line "+lexer.getNextLine());
        }
        varTable.put(name, varCount++);
    }

    /* 
       Finds the location of an existing variable.
       Throws Error if the variable does not exist.
    */
    private static int findVar( String name ) throws Exception
    {
        Integer res = varTable.get(name);
        if( res == null )
        {
            throw new Error("Variable "+name+" does not exist, near line "+lexer.getNextLine());
        }
        return res;
    }
    //--------------------------- GETTERS : END ----------------------------------

    //--------------------------- PARSER : START ---------------------------------
    private Object[] beginParse() throws Exception
    {
        Vector<Object> code = new Vector<Object>();
        try {
            while(lexer.getToken() != ENDOFFILE)
            {
                code.add(function());
            }
        } catch( Exception e )
        {
            System.err.println("Error on line "+lexer.getLine()+" at column "+lexer.getColumn()+": "+e.getMessage());
            throw new Error("Parsing Failed");
        }
        return code.toArray();
    }

    // Definition for function rule
    private Object function() throws Exception
    {
        Vector<Object> code = new Vector<Object>();
        if( lexer.getToken() == VAR )
        {
            code.add(advance()); // VAR
            String varName = lexer.getLexeme();
            code.add(advance()); // NAME
            addVar(varName);
            code.add(body());
        } 
        else if( lexer.getToken() == NAME )
        {
            code.add(body());
        }
        else
        {
            throwParserException("Expected either VAR or NAME, but got "+lexer.getLexeme());
        }
        return code.toArray();
    }

    // Definition for body rule
    private Object body() throws Exception
    {
        Vector<Object> code = new Vector<Object>();
        code.add(advance()); // NAME
        if( lexer.getToken() == '(' )
        {
            code.add(advance()); // '('
            code.add(expr());
            if( lexer.getToken() == ')' )
            {
                code.add(advance()); // ')'
            } 
            else
            {
                throwParserException("Expected ')' but got "+lexer.getLexeme());
            }
        } 
        else 
        {
            code.add(smallexpr());
        }
        return code.toArray();
    }

    // Definition for expr rule
    private Object expr() throws Exception
    {
        Vector<Object> code = new Vector<Object>();
        code.add(binopexpr());
        return code.toArray();
    }

    // Definition for binopexpr rule
    private Object binopexpr() throws Exception
    {
        Vector<Object> code = new Vector<Object>();
        code.add(smallexpr());
        if( lexer.getToken() == OPNAME )
        {
            code.add(advance()); // OPNAME
            code.add(smallexpr());
        }
        return code.toArray();
    }

    // Definition for smallexpr rule
    private Object smallexpr() throws Exception
    {
        Vector<Object> code = new Vector<Object>();
        if( lexer.getToken() == NAME )
        {
            code.add(advance()); // NAME
            if( lexer.getToken() == '(' )
            {
                code.add(advance()); // '('
                code.add(expr());
                if( lexer.getToken() == ')' )
                {
                    code.add(advance()); // ')'
                } 
                else
                {
                    throwParserException("Expected ')' but got "+lexer.getLexeme());
                }
            } 
            else
            {
                throwParserException("Expected '(' but got "+lexer.getLexeme());
            }
        } 
        else if( lexer.getToken() == LITERAL )
        {
            code.add(advance()); // LITERAL
        } 
        else 
        {
            throwParserException("Expected either NAME or LITERAL, but got "+lexer.getLexeme());
        }
        return code.toArray();
    }
    //--------------------------- PARSER : END -----------------------------------

    //--------------------------- HELPER FUNCTIONS : START ------------------------
    private int priority( String op )
    {
        if( op.equals("=") )
        {
            return 1;
        } 
        else if( op.equals("==") || op.equals("!=") )
        {
            return 2;
        } 
        else if( op.equals("<") || op.equals(">") || op.equals("<=") || op.equals(">=") )
        {
            return 3;
        } 
        else if( op.equals("+") || op.equals("-") )
        {
            return 4;
        } 
        else if( op.equals("*") || op.equals("/") )
        {
            return 5;
        } 
        else if( op.equals(".") )
        {
            return 6;
        } 
        else
        {
            return 0;
        }
    }

    private String TokenToName( int token )
    {
        switch( token )
        {
            case ENDOFFILE:
                return "EOF";
            case VAR:
                return "VAR";
            case LITERAL:
                return "LITERAL";
            case IF:
                return "IF";
            case ELSIF:
                return "ELSIF";
            case ELSE:
                return "ELSE";
            case WHILE:
                return "WHILE";
            case RETURN:
                return "RETURN";
            case NAME:
                return "NAME";
            case OPNAME:
                return "OPNAME";
            default:
                return "UNKNOWN";
        }
    }

    private void throwParserException( String message ) throws Exception
    {
        throw new Exception(message + ", near line " + lexer.getLine());
    }
    //--------------------------- HELPER FUNCTIONS : END --------------------------
%}
/* 
   ------------------------- Regular definitions ------------------------- 
*/

_DIGIT=[0-9]
_FLOAT={_DIGIT}+\.{_DIGIT}+([eE][+-]?{_DIGIT}+)?
_INT={_DIGIT}+
_STRING=\"([^\"\\]|\\b|\\t|\\n|\\f|\\r|\\\"|\\\'|\\\\|(\\[0-3][0-7][0-7])|\\[0-7][0-7]|\\[0-7])*\"
_CHAR=\'([^\'\\]|\\b|\\t|\\n|\\f|\\r|\\\"|\\\'|\\\\|(\\[0-3][0-7][0-7])|(\\[0-7][0-7])|(\\[0-7]))\'
_DELIM=[(){},;=]
_NAME=([:letter:]|\_|{_DIGIT})+
_OPNAME=[\+\-*/!%&=><\:\^\~&|?]+

%%

/* 
    ------------------------- Scanning rules -------------------------

    The way this is going to work is that JFlex will take all these rules
    and combine them into an NFA then it will take that NFA and convert it
    into a DFA. The string will be fed to the DFA and it will traverse 
    the DFA until it cant get any further at which point we backtrack to the 
    last accepting state that we found. Its important to know that the order
    of the scanning rules here matters since the rules that are defined
    first have a higher precedence over the rules that are defined later.
    If you dont follow this correctly, you can wind up with something like
    a keyword IF beeing a valid variable or function name.
*/

{_DELIM} {
	return yycharat(0);
}

{_STRING} | {_FLOAT} | {_CHAR} | {_INT} | null | true | false {
	return LITERAL;
}

"if" {
	return IF;
}

"elsif" {
	return ELSIF;
}

"else" {
	return ELSE;
}

"while" {
	return WHILE;
}

"return" {
	return RETURN;
}

"var" {
	return VAR;
}

{_NAME} {
	return NAME;
}

{_OPNAME} {
	return OPNAME;
}

/*
  The reason to why comments, spaces,tabs and carrige returns do not return a lexeme is because, 
  we do not care about it, this type of information should have no impact on the code.
*/

// ;;; are our comments, if the line starts with ;;; and is followed by zero or more characters its a comment.
";;;".*$ {
}

// If its a space, tab, carrige return, line or form feed we do nothing 
[ \t\r\n\f] {
}

. {
	return ERROR;
}
%%
