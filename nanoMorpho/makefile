NanoMorpho.java: nanomorhpo.jflex
	java -jar jflex-full-1.9.1.jar nanomorhpo.jflex
NanoMorpho.class: NanoMorpho.java
	javac NanoMorpho.java
clear_all:
	clear
test_success: NanoMorpho.class test_success.s
	java NanoMorpho test_success.s

Generate_morpho: 
	java NanoMorpho test_success.s | java -jar morpho.jar -c

Test_morpho_generated_code: 
	java -jar morpho.jar test_success
