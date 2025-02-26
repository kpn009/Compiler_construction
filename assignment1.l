%{
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#define NUM_OF_KEYWORDS 18 // this are total number of keywords in toy language
#define ID_LIMIT 256 //this is the max size of the string for any identifier in toy language
#define NUM_LIMIT 20 //max_limit for any integer in toy language
#define STR_LIMIT 256 //max_limit for any string in toy language
char var_name[ID_LIMIT];
char var_type[ID_LIMIT];
char op_string[STR_LIMIT];
char id_string[STR_LIMIT];
void print_token(char* lexeme, char* token_type);
int is_valid_integer(char* str);
int is_valid_identifier(char* str);
int is_keyword(char* str);
int validate_io(char* str1, char* str2, int io);
int is_declared(char* str, char** sym_tbl);
long long int capacity = 2;
long long int size = 0;
int cmt_count = 0;
int cmt_vdcl = 0;
char** sym_tbl;

%}

DIGIT [0-9]
LETTER [a-z]
SPECIAL_SYMBOL [+\-=%/*<>\(\);,:{}]
ID_ALPHABET [a-z0-9_]
WHITESPACE [ \t\n]
%x PRINT
%x SCAN
%x VARDECL
%x COMMENT

%%

"begin"|"program"|"int"|"char"|"if"|"else"|"while"|"for"|"main"|"end"|"inc"|"dec"|"then"|"to"|"do" {
    print_token(yytext, "Keyword");
}
"VarDecl" {print_token(yytext, "Keyword"); BEGIN(VARDECL);}
"print" {yyless(0); BEGIN(PRINT);}
"scan" {yyless(0); BEGIN(SCAN);}
":"|"("|")"|";"|","|"{"|"}" {print_token(yytext, "Separator");}
"+="|"-="|"*="|"%="|"/="|":=" {print_token(yytext, "Assignment operator");}
"+"|"-"|"*"|"%"|"/" {print_token(yytext, "Arithmetic operator");}
">"|"<"|">="|"<="|"<>"|"=" {print_token(yytext, "Relational operator");}

{ID_ALPHABET}* {
	char* id = yytext;
	if(is_valid_identifier(id)){
		if(is_declared(id, sym_tbl)) print_token(id, "Identifier");
		else{
			print_token(id, "Error : identifier has not been declared");
		}
	}
	else{
		print_token(id, "Error : invalid identifier");
	}
}

\([ \t]*{DIGIT}*[ \t]*,[ \t]*("2"|"8"|"10")[ \t]*\) {
    if(is_valid_integer(yytext) == 1) print_token(yytext, "Integer constant");
    else {
        print_token(yytext, "Error : invalid integer");
    }
}

"//".* { /*Ignore single line comments*/}
"/*" {cmt_count++; BEGIN(COMMENT);}

{WHITESPACE}+ {/*Ignore whitespaces*/}
. {print_token(yytext,"Error : invalid token");}

<VARDECL>: {print_token(yytext, "Separator");}
<VARDECL>\([ \t]*{LETTER}{ID_ALPHABET}*[ \t]*,[ \t]*(int|char)[ \t]*\) {
	sscanf(yytext, "(%[^,], %[^)])", var_name, var_type);
	print_token("(", "Separator");
	if(!is_declared(var_name, sym_tbl)){
		if((is_valid_identifier(var_name) == 1) && (is_keyword(var_name) == 0)) {
			print_token(var_name, "Identifier");
		}
		else{
			if(is_keyword(var_name)) print_token(var_name, "Error : keyword is used as an identifier");
			else print_token(var_name, "Error : invalid identifier");
		}
	}
	else{
		print_token(var_name, "Error : identifier already declared");
	}
	print_token(",", "Separator");
	if(is_keyword(var_type) == 1) {
		print_token(var_type, "Keyword");
		print_token(")", "Seperator");
		if(size == capacity){
			capacity *= 2;
			sym_tbl = (char**)realloc(sym_tbl, capacity*sizeof(char*));
			if(sym_tbl == NULL){
				printf("Memory allocation failed!\n");
				exit(2);
			}
		}
		sym_tbl[size] = (char*)malloc((256)*sizeof(char));
		if(sym_tbl == NULL){
			printf("Memory allocation failed!\n");
			exit(1);
		}
		strcpy(sym_tbl[size], var_name);
		sym_tbl[size][strlen(var_name)] = '\0';
		size++;
	}
	else{
		print_token(var_type, "Error : invalid identifier type");
	}
}
<VARDECL>";" {print_token(yytext, "Separator");}
<VARDECL>"end" {print_token(yytext, "Keyword");}
<VARDECL>"VarDecl" {print_token(yytext, "Keyword"); BEGIN(0);}
<VARDECL>{WHITESPACE}+ {/*Ignore whitespace*/}
<VARDECL>[^ \t\n]+ {
	if(strcmp(yytext, "end") != 0 && strcmp(yytext, "VarDecl") != 0){
		print_token(yytext, "Error : invalid token");
	}
	else REJECT;
}
<VARDECL>"//".* { /*Ignore single line comments*/}
<VARDECL>"/*" {cmt_count++; cmt_vdcl = 1; BEGIN(COMMENT);}
<PRINT>[ \t]*print\([ \t]*\"[^\"]*\"[ \t]*[^)]*\); {
	sscanf(yytext, "print(\"%255[^\"]\",%255[^)])", op_string, id_string);
	if(validate_io(op_string, id_string, 0)){
		print_token(yytext, "Valid output statement");
	}
	else{
		print_token(yytext, "Error : invalid output statement");
	}
}
<PRINT>.+ {print_token(yytext, "Error : invalid output statement");}
<PRINT>"\n" {BEGIN(0);}
<SCAN>[ \t]*scan\([ \t]*\"[^\"]*\"[ \t]*[^)]*\); {
	sscanf(yytext, "scan(\" %255[^\"] \",%255[^)])", op_string, id_string);
	if(validate_io(op_string, id_string, 1)){
		print_token(yytext, "Valid input statement");
	}
	else{
		print_token(yytext, "Error : invalid input statement");
	}
}
<SCAN>"\n" {BEGIN(0);}
<SCAN>. {print_token(yytext, "Error : Invalid input statement");}
<COMMENT>"/*" {cmt_count++;}
<COMMENT>.|"\n" {}
<COMMENT>"*/" {
	cmt_count--;
	if(cmt_count == 0){
		if(cmt_vdcl) BEGIN(VARDECL);
		else BEGIN(0);
	}
}

%%

void print_token(char* lexeme, char* token){
	printf("%-20s %s\n", lexeme, token);
}

int is_valid_integer(char* str){
	int value, base;
	if(sscanf(str, "(%d, %d)", &value, &base) == 2){
		if(base == 2 || base == 8 || base == 10){
			char* num_start = strchr(str, '(') + 1;
			char* num_end = strchr(str, ',');
			int num_len = num_end - num_start;
			char num_str[NUM_LIMIT];
			strncpy(num_str, num_start, num_len);
			num_str[num_len] = '\0';
			if(base == 2 && strspn(num_str, "01") == strlen(num_str)) return 1;
			if(base == 8 && strspn(num_str, "01234567") == strlen(num_str)) return 1;
			if(base == 10) return 1;
		}
	}
	return 0;
}

int is_valid_identifier(char* str){
	if(strlen(str) > ID_LIMIT) return 0;
	if(!islower(str[0])) return 0;
	int underscore_count = 0;
	for(int i = 1; str[i] != '\0'; i++){
		if(str[i] == '_') underscore_count ++;
		else if(!islower(str[i]) && !isdigit(str[i])) return 0;
	}
	return (underscore_count <= 1);
}

int is_keyword(char* str){
	const char* keywords[] = {"begin", "program", "int", "char", "if", "else", "while", "for", "main", "end", "print", "scan", "inc", "dec", "then", "to", "do", "VarDecl"};
	for(int i = 0; i < NUM_OF_KEYWORDS; i++){
		if(strcmp(str, keywords[i]) == 0) return 1;
	}
	return 0;
}

int  is_declared(char* str, char** sym_tbl){
	for(int i = 0; i < size; i++){
		if(strcmp(str, sym_tbl[i]) == 0) return 1;
	}
	return 0;
}

int validate_io(char* str1, char* str2, int io){
	int cnt_a = 0;
	int cnt_comma = 0;
	int cnt_id = 0;
	for(int i = 0; str1[i] != '\0'; i++){
		if(str1[i] == '@') cnt_a++;
		if(str1[i] == ',') cnt_comma ++;
		if((str1[i] != '@') && (str1[i] != ' ') && (str1[i] != ',') && (str1[i] != '\t') && (str1[i] != '\n') && (str1[i] != '\r') && (str1[i] != '\v') && (str1[i] != '\f') && (io == 1)) return 0;
 	}
	char* token = strtok(str2, ", ");
	while(token != NULL){
		if((is_keyword(token) == 0) && (is_valid_identifier(token) == 1)&& (is_declared(token, sym_tbl) == 1)) cnt_id ++;
		else return 0;
		token = strtok(NULL, " ");
	}
	if((io == 0) && (cnt_a == cnt_id)) return 1;
	else if((io == 1) && (cnt_a == cnt_id) && (cnt_a == cnt_comma + 1)) return 1;
	else return 0;
}

int main(){
	sym_tbl= (char**)malloc(capacity*sizeof(char*));
	if(sym_tbl == NULL){
		perror("Memory allocation failed\n");
		exit(1);
	}
	for(int i = 0; i < capacity; i++) sym_tbl[i] = NULL;
	FILE* file = fopen("input.txt", "r");
	yyin = file;
	print_token("LEXEME", "TOKEN");
	print_token("--------------", "--------------");
	yylex();
	fclose(yyin);
	for(int i = 0; i < size; i++){
		free(sym_tbl[i]);
	}
	free(sym_tbl);
	return 0;
}
