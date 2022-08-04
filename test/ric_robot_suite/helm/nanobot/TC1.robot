*** Settings ***
Documentation    Suite description
Library    Collections

*** Test Cases ***
TC1
	${list} =    create list    a    abc    bad
	${count} =     Get Match Count    ${list}   *a*
	LOG TO CONSOLE      ${count}
