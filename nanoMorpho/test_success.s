;;; TESTS :
;;; - variable assignment (in different orders)
;;; - printing out string variables
;;; - changing the value of an already assigned variable
;;; - String concatenation of strings and string variables
string_Tests()
{
	var firstString, secondString;
	secondString = " Greetings!";
	firstString = "Hello universe";
	writeln(firstString);
	firstString = "Hello again";
	writeln(firstString);
	
	writeln("123"++"456");
	writeln(firstString++secondString);
	newLine();
}

;;; TESTS :
;;; - variable assignment
;;; - Adding integers and variables 
;;; - concatenation of string and integers
;;; - floating point math 
math_Tests()
{
	var num1, num2, num3;
	num1 = 1;
	num2 = 2;
	num3 = 3;
	writeln("Adding integers " ++ (1+2+3));
	writeln("Adding variables " ++ (num1+num2+num3));
	writeln(1.0+2.0+3.0);
	writeln(1.0+2.0+3.0+1.0/3.0);
	newLine();
}

;;; TESTS :
;;; - variable assignment
;;; - creating list with integers and null 
;;; - creating list with integers
;;; - creating list with strings
;;; - creating list from from variable values
;;; - creating list from functions that return values 
list_Tests()
{
	var a, b, c, m;
	b = 1;
	a = 2;
	writeln(1:null);
	writeln(1:2:3);
	writeln(b:2);
	writeln(b:a);
	writeln(head(b:a));
	writeln(tail(b:a));
	writeln(head(b:a):tail(b:a));
	c = "first";
	m = "second";
	writeln("first":"second");
	writeln(c:m);
	writeln(head(c:m));
	writeln(tail(c:m));
	writeln(head(c:m):tail(c:m));
	newLine();
}

;;; TESTS :
;;; - reciving and using arguments
;;; - condional flows 
;;; - body expressions inside IF statements
conditional_Tests(firstArg, secondArg)
{
	writeln("conditional_Tests called with firstArg="++firstArg++" secondArg="++ secondArg);
	if(firstArg)
	{
		if(secondArg)
		{
			writeln("result: firstArg="++firstArg++" secondArg="++ secondArg);
		}
		else
		{
			writeln("result: firstArg="++firstArg++" secondArg="++ secondArg);
		};
	}
	else{
		if(secondArg)
		{
			writeln("result: firstArg="++firstArg++" secondArg="++ secondArg);
		}
		else
		{
			writeln("result: firstArg="++firstArg++" secondArg="++ secondArg);
		};
	};

	;;; Tests IF(expressions) and elsif(expressions)
	if(firstArg == true && secondArg == false){
		writeln("reached when firstArg is true and secondArg is false");
	}
	elsif(firstArg == false && secondArg == true)
	{
		writeln("reached when firstArg is false and secondArg is true");
	}
	else{
		writeln("reached correct.");
	};
	
	newLine();
}

;;; TESTS :
;;; - only having if no else
;;; - having if and elsif's but no else
edgecase_conditional_Tests(arg)
{
	if(arg)
	{
		writeln("if condition with no else is reached");
	};

	if(arg)
	{
		writeln("if condition with elsif but no else is reached");
	}
	elsif(!arg)
	{
		writeln("elseif condition with no else is reached");
	};

}

;;; fibo and f are from test.nm from nanomorphoparser.zip in ugla 
fibo(n)
{
	var i, fib1, fib2, temp;
	fib1 = 1;
	fib2 = 1;
	i = 0;
	while( i!=n )
	{
		temp = fib1+fib2;
		fib1 = fib2;
		fib2 = temp;
		i = i+1;
	};
	newLine();
	fib1;
}

f(n)
{
	if( n<2 )
	{
		1;
	}
	else
	{
		f(n-1) + f(n-2);
	};
}

newLine()
{
	writeln("");
}

main()
{
	string_Tests();
	math_Tests();
	list_Tests();
	conditional_Tests(true,true);
	conditional_Tests(true,false);
	conditional_Tests(false,true);
	conditional_Tests(false,false);
	edgecase_conditional_Tests(true);
	edgecase_conditional_Tests(false);
	writeln("none-recursive fibo(35)="++fibo(35));
	writeln("recursive fibo(35)="++f(35));
}
