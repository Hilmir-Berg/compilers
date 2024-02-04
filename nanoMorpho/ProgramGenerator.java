
public class ProgramGenerator
{
    // Constants that represent the assembler functions to call.
    public final static String EXPRESSION_RETURN = "RETURN";
    public final static String EXPRESSION_STORE = "STORE";
    public final static String EXPRESSION_CALL = "CALL";
    public final static String EXPRESSION_FETCH = "FETCH";
    public final static String EXPRESSION_LITERAL = "LITERAL";
    public final static String EXPRESSION_IF = "IF";
    public final static String EXPRESSION_WHILE = "WHILE";
    public final static String EXPRESSION_BODY = "BODY";
    
    /*
        We need some types of unique labels to jump to (Go,GoFalse,GoTrue) in our generated code
        the easiest and most simple one is auto incremented integers with the '_' prefix
        _1, _2, _3 ... 
     */
    private static int nextLabel = 1;

    public void main(String[] args) {
        
    }

    /*
       Just to avoid writing System.out.println(line); 10 quintillion times
       we create a function with a small name that prints out whatever we need.
    */ 
	private static void emit(String line )
	{
		System.out.println(line);
    }
    
    /*
        Usage: newLabel()
          For: nothing
        After: Returns nextLabel integer value and increments the nextLabel by 1.
     */
	private static int newLabel()
	{
		return nextLabel++;
    }
    
    /*
        Usage: generateProgram(filename,funs)
          For: - filename is a string that contains the filename of the program to generate
               - funs is an object array where each entry is an array of the form [String, int, int, Object[]]
                 NOTE: one funs entries must have string value of "main"
        After: prints out morpho program named filename with the input provoided from funs.
     */
    public void generateProgram(String filename, Object[] funs)
    {
        String programname = filename.substring(0,filename.indexOf('.'));
        System.out.println("\""+programname+".mexe\" = main in");
        System.out.println("!");
        System.out.println("{{");
        for(int i = 0; i < funs.length; i++)
        {
            generateFunction((Object[])funs[i]);
        }
        System.out.println("}}");
        System.out.println("*");
        System.out.println("BASIS;");
    }

    /*
        Usage: generateFunction(f)
          For: - f is an object array of the form [String, int, int, Object[]]
        After: prints out a morpho function with the input provoided.
     */
    private void generateFunction(Object[] f)
    {
        /*
            Example of the desired result

            This:
                f = fun(x1 ,..., xN)
                {
                   var y1=g1 ,..., yM=gM;
                    s1;
                    ...
                    sP;
                };
            Translates to this:
                #"f [fN]" =
                    [
                        Þ[g1]
                        (Push)
                        ...
                        Þ[gM]
                        (Push)
                        Þ[s1]
                        ...
                        Þ[sP]
                        (Return)
                    ]
        */
        String fname = (String)f[0];
        int argCount = (Integer)f[1];
        int varCount = (Integer)f[2];
		emit("#\""+fname+"[f"+argCount+"]\" =");
        emit("[");
        /* 
            When we enter a function we only know the positions of the arguments,
            there are no initialized positions for the variables so to fix this we create null and push it
            to all the variable positions that way we have initialized all the variable positions. 
         */
        if(varCount > 0 )
        {
            emit("(MakeVal null)");
            for(int i = 0; i < varCount; i++)
            {
                emit("(Push)");
            }
        }
        for (Object expr : (Object[])f[3])
        {
            generateExpr((Object[])expr);
        }
        emit("(Return)");
		emit("];");
    }

    /*
        Usage: generateExpr(expr)
          For: - expr is an object array that can be one of the following
                   ["RETURN",expr]
                   ["STORE",pos,expr]
                   ["CALL",name,args]
                   ["FETCH",pos]
                   ["LITERAL",string]
                   ["IF",expr,expr,expr]
                   ["WHILE",expr,expr]
                   ["BODY",exprs]
        After:  prints out the nessesary morpho assembler calls to create the given expr.
     */
    private void generateExpr(Object[] expr)
    {
           switch ((String)((Object[])expr)[0])
           {
              case EXPRESSION_RETURN:
                //["RETURN",expr]
                generateExprP((Object[])((Object[])expr)[1]);
                emit("(Return)");
                break;
              case EXPRESSION_CALL:
                //["CALL",name,args]
                Object[] args = (Object[])((Object[])expr)[2];
                int i;
                for(i=0; i != args.length; i++)
                {
                    /*
                       Need to remember that when calling something the order should be
                       0: generateExpr
                       1: push
                          generateExpr
                       2: push
                          generateExpr
                          ..
                          ..
                     */
                    if(i==0)
                    {
                        generateExpr((Object[])args[i]);
                    }
                    else
                    {
                        generateExprP((Object[])args[i]);
                    }
                }
                emit("(Call #\""+(String)((Object[])expr)[1]+"[f"+i+"]\" "+i+")");
                break;
              case EXPRESSION_FETCH:
                //["FETCH",pos]
                emit("(Fetch "+(int)((Object[])expr)[1]+")");
                break;
              case EXPRESSION_LITERAL:
                //["LITERAL",string]
                emit("(MakeVal "+(String)((Object[])expr)[1]+")");
                break;
              case EXPRESSION_IF:
                //["IF",expr,expr,expr]
                //      con  then  else
                int labElse = newLabel();
                int labEnd = newLabel();
                generateJump(((Object[])(((Object[])expr)[1])),0,labElse);
                generateExpr(((Object[])(((Object[])expr)[2])));
                emit("(Go _"+labEnd+")");
                emit("_"+labElse+":");

                /* 
                  because the way our code is generated in nanomorhpo.jflex
                  there will be a case where the 3rd value will be null.
                */
                if(((Object[])(((Object[])expr)[3])) != null)
                {
                    generateExpr(((Object[])(((Object[])expr)[3])));
                }
                emit("_"+labEnd+":");
                break;
              case EXPRESSION_WHILE:
                //["WHILE",expr,expr]
                int labTrue = newLabel();
                int labFalse = newLabel();
                emit("_"+labTrue+":");
                generateJump(((Object[])(((Object[])expr)[1])),0,labFalse);
                generateExpr(((Object[])(((Object[])expr)[2])));
                emit("(Go _"+labTrue+")");
                emit("_"+labFalse+":");
                break;
              case EXPRESSION_STORE:
                //["STORE",pos,expr]
                generateExpr((Object[])((Object[])expr)[2]);
                emit("(Store "+(int)((Object[])expr)[1]+")");
                break;
              case EXPRESSION_BODY:
                //["BODY",exprs]
                for (Object b_expr : (Object[])expr[1])
                {
                    generateExpr((Object[])b_expr);
                }
                break;
              default:
                throw new Error("Unknown intermediate code type: \""+(String)((Object[])expr)[0]+"\"");
           }
    }

    /*
        Usage: generateExpr(expr)
          For: - expr is an object array that can be one of the following
                   ["RETURN",expr]
                   ["STORE",pos,expr]
                   ["CALL",name,args]
                   ["FETCH",pos]
                   ["LITERAL",string]
                   ["IF",expr,expr,expr]
                   ["WHILE",expr,expr]
                   ["BODY",exprs]
                NOTE: Atm only accepts 3 out 8, dont know if it should support all
        After:  prints out the nessesary morpho assembler calls but with (Push) prepented.
                i.e  
                (Push)
                generateExpr(expr)
     */
    private void generateExprP(Object[] expr)
    {
        switch ((String)((Object[])expr)[0])
        {
            case EXPRESSION_CALL:
                Object[] args = (Object[])((Object[])expr)[2];
                int i;
                for(i=0; i != args.length; i++)
                {
                    generateExprP((Object[])args[i]);
                }
                if( i==0 )
                { 
                    emit("(Push)");
                }
                emit("(Call #\""+(String)((Object[])expr)[1]+"[f"+i+"]\" "+i+")");
                break;
            case EXPRESSION_FETCH:
                //["FETCH",pos]
                emit("(FetchP "+(int)((Object[])expr)[1]+")");
                break;
            case EXPRESSION_LITERAL:
                //["LITERAL",string]
                emit("(MakeValP "+(String)((Object[])expr)[1]+")");
                break;
            default:
                throw new Error("Unknown intermediate code type: \""+(String)((Object[])expr)[0]+"\"");
		}
    }

    private void generateJump(Object[] exr, int labelTrue, int labelFalse )
	{
		switch((String)exr[0])
		{
            case EXPRESSION_LITERAL:
                 //["LITERAL",string]
                String literal = (String)exr[1];
                if(literal.equals("false") || literal.equals("null"))
                {
                    if( labelFalse!=0 ) emit("(Go _"+labelFalse+")");
                    return;
                }
                if( labelTrue!=0 ) emit("(Go _"+labelTrue+")");
                return;
        default:
			generateExpr(exr);
			if( labelTrue!=0 ) emit("(GoTrue _"+labelTrue+")");
			if( labelFalse!=0 ) emit("(GoFalse _"+labelFalse+")");
		}
	}
}