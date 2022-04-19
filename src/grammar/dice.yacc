/* Uncomment for better errors! (non-POSIX compliant) */
/* %define parse.error verbose */

%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <limits.h>
#include <stdbool.h>
#include "yacc_header.h"
#include "vector_functions.h"
#include "shared_header.h"
#include "dice_logic.h"
#include "uthash.h"

#define UNUSED(x) (void)(x)

int yylex(void);
int yyerror(const char* s);

int yydebug=1;
MOCK_METHOD mock_style=NO_MOCK;
int mock_return_value = 0;
int mock_constant = 0;
bool verbose = true;
bool seeded = false;
bool write_to_file = false;
char * output_file;

// Registers

// TODO: It would be better to fit arbitrary length strings.
unsigned int MAX_SYMBOL_TEXT_LENGTH = 100;

struct macro_struct {
    int id;                    /* key */
    // char name[MAX_SYMBOL_TEXT_LENGTH];
    vec stored_dice_roll;
    UT_hash_handle hh;         /* makes this structure hashable */
};
struct macro_struct *macros = NULL; //Initialized to NULL (Importnat)

void register_macro(char * skey, vec *to_store) {
    int key = atoi(skey);

    struct macro_struct *s;

    HASH_FIND_INT(macros, &key, s);  /* id already in the hash? */
    if (s == NULL){
        s = (struct macro_struct*)malloc(sizeof *s);
        s->id = key;
        HASH_ADD_INT(macros, id, s);  /* id: name of key field */
    }
    memcpy(&s->stored_dice_roll, &to_store, sizeof(to_store));
}
struct macro_struct *search_macros(char * skey, vec *to_store) {
    int key = atoi(skey);
    struct macro_struct *s;

    HASH_FIND_INT(macros, &key, s);  /* s: output pointer */
    return s;
}


int initialize(){

    if (!seeded){
        srand(time(0));
        seeded = true;
    }
    return 0;
}

int collapse(int * arr, int len){
    return sum(arr, len);
}

int sum(int * arr, int len){
    int result = 0;
    for(int i = 0; i != len; i++) result += arr[i];
    return result;
}

int roll_numeric_die(int small, int big){
    int v = 0;
    if (mock_style == RETURN_INCREMENTING){
        mock_return_value++;
        v = mock_return_value;
    }else if (mock_style == RETURN_DECREMENTING){
        mock_return_value++;
        v = mock_return_value;
    }else{
        v = mock_constant;
    }
    return random_fn(small, big, mock_style, v);
}
int roll_symbolic_die(int length_of_symbolic_array){
    // Returns random index into symbolic array
    return roll_numeric_die(0, length_of_symbolic_array -1);
}

%}


%start dice

%token NUMBER SIDED_DIE FATE_DIE REPEAT PENETRATE
%token MACRO_ACCESSOR MACRO_STORAGE MACRO_SEPERATOR ASSIGNMENT
%token DIE
%token KEEP_LOWEST KEEP_HIGHEST
%token LBRACE RBRACE PLUS MINUS MULT MODULO DIVIDE_ROUND_UP DIVIDE_ROUND_DOWN
%token EXPLOSION IMPLOSION REROLL_IF
%token SYMBOL_LBRACE SYMBOL_RBRACE SYMBOL_SEPERATOR CAPITAL_STRING

%token NE EQ GT LT LE GE

/* Defines Precedence from Lowest to Highest */
%left PLUS MINUS
%left MULT DIVIDE_ROUND_DOWN DIVIDE_ROUND_UP MODULO
%left KEEP_LOWEST KEEP_HIGHEST
%left UMINUS
%left LBRACE RBRACE

%union{
    vec values;
}
/* %type<die> DIE; */
/* %type<values> NUMBER; */

%%
/* Rules Section */

dice:
    macros executable_statement
    |
    executable_statement
;
macros:
    MACRO_STORAGE CAPITAL_STRING ASSIGNMENT custom_symbol_dice MACRO_SEPERATOR {
        vec key = $<values>2;
        vec value = $<values>4;

        register_macro(key.symbols[0], &value);
    }
;

executable_statement: collapsed_roll_statement{
    vec vector;
    vector = $<values>1;
    FILE *fp;

    if(write_to_file){
        fp = fopen(output_file, "w+");
    }

    for(int i = 0; i!= vector.length;i++){
        if (vector.dtype == SYMBOLIC){
            // TODO: Strings >1 character
            if (verbose){
                printf("%s", vector.symbols[i]);
            }
            if(write_to_file){
                fprintf(fp, "%s", vector.symbols[i]);
            }
        }else{
            if(verbose){
                printf("%d", vector.content[i]);
            }
            if(write_to_file){
                fprintf(fp, "%d", vector.content[i]);
            }
        }
    }
    if(verbose){
        printf("\n");
    }

    if(write_to_file){
        fclose(fp);
    }
}

collapsed_roll_statement: roll_statement{
    vec vector;
    vector = $<values>1;

    if (vector.dtype == SYMBOLIC){
        $<values>$ = vector;
    }else{
        int c = 0;
        for(int i = 0; i != vector.length; i++){
            c += vector.content[i];
        }

        vec new_vec;
        new_vec.content = calloc(sizeof(int), 1);
        new_vec.content[0] = c;
        new_vec.length = 1;
        new_vec.dtype = vector.dtype;

        $<values>$ = new_vec;
    }
}

roll_statement: math;

math:
    LBRACE math RBRACE{
        $<values>$ =  $<values>2;
    }
    |
    math MULT math{
        // Collapse both sides and subtract
        vec vector1;
        vec vector2;
        vector1 = $<values>1;
        vector2 = $<values>3;

        if (vector1.dtype == SYMBOLIC || vector2.dtype == SYMBOLIC){
            printf("Division unsupported for symbolic dice.");
            YYABORT;
            yyclearin;
        }else{
            int v1 = collapse(vector1.content, vector1.length);
            int v2 = collapse(vector2.content, vector2.length);

            vec new_vec;
            new_vec.content = calloc(sizeof(int), 1);
            new_vec.length = 1;
            new_vec.content[0] = v1 * v2;
            new_vec.dtype = vector1.dtype;

            $<values>$ = new_vec;
        }
    }
    |
    math DIVIDE_ROUND_UP math{
        // Collapse both sides and subtract
        vec vector1;
        vec vector2;
        vector1 = $<values>1;
        vector2 = $<values>3;

        if (vector1.dtype == SYMBOLIC || vector2.dtype == SYMBOLIC){
            printf("Division unsupported for symbolic dice.");
            YYABORT;
            yyclearin;
        }else{
            int v1 = collapse(vector1.content, vector1.length);
            int v2 = collapse(vector2.content, vector2.length);

            vec new_vec;
            new_vec.content = calloc(sizeof(int), 1);
            new_vec.length = 1;
            new_vec.content[0] = (v1+(v2-1))/ v2;
            new_vec.dtype = vector1.dtype;

            $<values>$ = new_vec;
        }
    }
    |
    math DIVIDE_ROUND_DOWN math{
        // Collapse both sides and subtract
        vec vector1;
        vec vector2;
        vector1 = $<values>1;
        vector2 = $<values>3;

        if (vector1.dtype == SYMBOLIC || vector2.dtype == SYMBOLIC){
            printf("Modulo unsupported for symbolic dice.");
            YYABORT;
            yyclearin;
        }else{
            int v1 = collapse(vector1.content, vector1.length);
            int v2 = collapse(vector2.content, vector2.length);

            vec new_vec;
            new_vec.content = calloc(sizeof(int), 1);
            new_vec.length = 1;
            new_vec.content[0] = v1 / v2;
            new_vec.dtype = vector1.dtype;

            $<values>$ = new_vec;
        }
    }
    |
    math MODULO math{
        // Collapse both sides and subtract
        vec vector1;
        vec vector2;

        vector1 = $<values>1;
        vector2 = $<values>3;

        if (vector1.dtype == SYMBOLIC || vector2.dtype == SYMBOLIC){
            printf("Modulo unsupported for symbolic dice.");
            YYABORT;
            yyclearin;
        }else{
            int v1 = collapse(vector1.content, vector1.length);
            int v2 = collapse(vector2.content, vector2.length);

            vec new_vec;
            new_vec.content = calloc(sizeof(int), 1);
            new_vec.length = 1;
            new_vec.content[0] = v1 % v2;
            new_vec.dtype = vector1.dtype;

            $<values>$ = new_vec;
        }
    }
    |
    math PLUS math{
        // Collapse both sides and subtract
        vec vector1;
        vec vector2;
        vector1 = $<values>1;
        vector2 = $<values>3;

        if (
            (vector1.dtype == SYMBOLIC && vector2.dtype == NUMERIC) ||
            (vector2.dtype == SYMBOLIC && vector1.dtype == NUMERIC)
        ){
            printf("Subtract not supported with mixed dice types.");
            YYABORT;
            yyclearin;
        } else if (vector1.dtype == SYMBOLIC){
            vec new_vec;
            unsigned int concat_length = vector1.length + vector2.length;
            new_vec.symbols = calloc(sizeof(char *), concat_length);
            for (int i = 0; i != concat_length; i++){
                new_vec.symbols[i] = calloc(sizeof(char), MAX_SYMBOL_TEXT_LENGTH);
            }
            new_vec.length = concat_length;
            new_vec.dtype = vector1.dtype;

            concat_symbols(
                vector1.symbols, vector1.length,
                vector2.symbols, vector2.length,
                new_vec.symbols
            );
            // free(vector1.symbols);
            // free(vector2.symbols);

            $<values>$ = new_vec;

        }else{
            int v1 = collapse(vector1.content, vector1.length);
            int v2 = collapse(vector2.content, vector2.length);

            vec new_vec;
            new_vec.content = calloc(sizeof(int), 1);
            new_vec.length = 1;
            new_vec.dtype = vector1.dtype;
            new_vec.content[0] = v1 + v2;

            $<values>$ = new_vec;
        }

    }
    |
    math MINUS math{
        vec vector1;
        vec vector2;
        vector1 = $<values>1;
        vector2 = $<values>3;
        if (
            (vector1.dtype == SYMBOLIC || vector2.dtype == SYMBOLIC)
        ){
            // It's not clear whether {+,-} - {-, 0} should be {+} or {+, 0}!
            // Therfore, we'll exclude it.
            printf("Subtract not supported with symbolic dice.");
            YYABORT;
            yyclearin;
        }else{
            // Collapse both sides and subtract

            int v1 = collapse(vector1.content, vector1.length);
            int v2 = collapse(vector2.content, vector2.length);

            vec new_vec;
            new_vec.content = calloc(sizeof(int), 1);
            new_vec.length = 1;
            new_vec.content[0] = v1 - v2;
            new_vec.dtype = vector1.dtype;

            $<values>$ = new_vec;
        }

    }
    |
    MINUS math %prec UMINUS{
        // Eltwise Negation
        vec vector;
        vector = $<values>2;

        if (vector.dtype == SYMBOLIC){
            printf("Symbolic Dice, Cannot negate. Consider using Numeric dice or post-processing.");
            YYABORT;
            yyclearin;
        } else {
            vec new_vec;

            new_vec.content = calloc(sizeof(int), vector.length);
            new_vec.length = vector.length;
            new_vec.dtype = vector.dtype;

            for(int i = 0; i != vector.length; i++){
                new_vec.content[i] = - vector.content[i];
            }
            $<values>$ = new_vec;

        }
    }
    |
    drop_keep
;


drop_keep:

    /* REROLL_IF drop_keep EQ NUMBER{

    }
    | */
    die_roll KEEP_HIGHEST NUMBER
    {
        vec roll_vector, keep_vector;
        roll_vector = $<values>1;
        keep_vector = $<values>3;

        if (roll_vector.dtype == SYMBOLIC){
            if(verbose) printf("Symbolic Dice, Cannot determine value. Consider using filters instead");
            YYABORT;
            yyclearin;
        }
        // assert $0 is len 1
        int available_amount =roll_vector.length;
        int amount_to_keep = keep_vector.content[0];

        if(available_amount > amount_to_keep){
            vec new_vector;
            new_vector.content = calloc(sizeof(int), amount_to_keep);
            new_vector.length = amount_to_keep;

            int * arr = roll_vector.content;
            int * new_arr;
            int len = roll_vector.length;

            for(int i = 0; i != amount_to_keep; i++){
                int m =  max(arr, len);
                new_vector.content[i] = m;
                new_arr = calloc(sizeof(int), (len-1));
                pop(arr,len,m,new_arr);
                free(arr);
                arr = new_arr;
                len -= 1;
            }

            new_vector.dtype = roll_vector.dtype;
            $<values>$ = new_vector;
        }else{
            // Warning: More asked to keep than actually produced
            // or the same amount
            // e.g. 2d20k4 / 2d20kh2
            $<values>$ = $<values>1;
        }
    }
    |
    die_roll KEEP_LOWEST NUMBER
    {
        vec roll_vector, keep_vector;
        roll_vector = $<values>1;
        keep_vector = $<values>3;

        if (roll_vector.dtype == SYMBOLIC){
            printf("Symbolic Dice, Cannot determine value. Consider using filters instead");
            YYABORT;
            yyclearin;
        }
        // assert $0 is len 1
        int available_amount =roll_vector.length;
        int amount_to_keep = keep_vector.content[0];

        if(available_amount > amount_to_keep){
            vec new_vector;
            new_vector.content = calloc(sizeof(int), amount_to_keep);
            new_vector.length = amount_to_keep;

            int * arr = roll_vector.content;
            int * new_arr;
            int len = roll_vector.length;

            for(int i = 0; i != amount_to_keep; i++){
                int m =  min(arr, len);
                new_vector.content[i] = m;
                new_arr = calloc(sizeof(int), len-1);
                pop(arr,len,m,new_arr);
                free(arr);
                arr = new_arr;
                len -= 1;
            }

            new_vector.dtype = roll_vector.dtype;
            $<values>$ = new_vector;
        }else{
            // Warning: More asked to keep than actually produced
            // or the same amount
            // e.g. 2d20k4 / 2d20kh2
            $<values>$ = $<values>1;
        }
    }
    |
    die_roll KEEP_HIGHEST
    {
        if ($<values>1.dtype == SYMBOLIC){
            printf("Symbolic Dice, Cannot determine value. Consider using filters instead");
            YYABORT;
            yyclearin;
        }
        if($<values>1.length > 1){
            // print_vec($<values>1);
            int result = max($<values>1.content, $<values>1.length);
            vec vector;
            vector.content = calloc(sizeof(int), 1);
            vector.content[0] = result;
            vector.length = 1;
            vector.dtype = $<values>1.dtype;
            $<values>$ = vector;
        }else{
            $<values>$ = $<values>1;
        }
    }
    |
    die_roll KEEP_LOWEST
    {
        // print_vec($<values>1);
        if ($<values>1.dtype == SYMBOLIC){
            printf("Symbolic Dice, Cannot determine value. Consider using filters instead");
            YYABORT;
            yyclearin;
        }
        if($<values>1.length > 1){
            // print_vec($<values>1);
            int result = min($<values>1.content, $<values>1.length);
            vec vector;
            vector.content = calloc(sizeof(int), 1);
            vector.content[0] = result;
            vector.length = 1;
            vector.dtype = $<values>1.dtype;
            $<values>$ = vector;
        }else{
            $<values>$ = $<values>1;
        }
    }
    |
    die_roll
    {
        vec vector;
        vector = $<values>1;

        if (vector.dtype == SYMBOLIC){
            // Symbolic, Impossible to collapse
            $<values>$ = vector;
        }
        else{
            // Numeric.
            // Collapse if Nessicary
            if(vector.length > 1){
                int result = sum(vector.content, vector.length);
                vec new_vec;
                new_vec.dtype = vector.dtype;
                new_vec.content = calloc(sizeof(int), 1);
                new_vec.content[0] = result;
                new_vec.length = 1;
                $<values>$ = new_vec;
            }else{
                $<values>$ = vector;
            }

        }
    }
;

die_roll:
   NUMBER SIDED_DIE NUMBER EXPLOSION
    {
        vec vector;
        vector = $<values>3;
        int max = vector.content[0];

        vec vector2;
        vector2 = $<values>1;
        int amount = vector2.content[0];


        int err = validate_roll(1, max);
        if (err){
            YYABORT;
            yyclearin;
        }else{
            // e.g. d4, it is implied that it is a single dice
            int result = perform_roll(amount, max, true, mock_style, mock_constant);

            vec new_vector;
            new_vector.content = calloc(sizeof(int), 1);
            new_vector.content[0] = result;
            new_vector.length = 1;
            new_vector.dtype = NUMERIC;

            $<values>$ = new_vector;
        }
    }
    |
    SIDED_DIE NUMBER EXPLOSION
    {
        vec vector;
        vector = $<values>2;
        int max = vector.content[0];


        int err = validate_roll(1, max);
        if (err){
            YYABORT;
            yyclearin;
        }else{
            // e.g. d4, it is implied that it is a single dice
            int result = perform_roll(1, max, true, mock_style, mock_constant);

            vec new_vector;
            new_vector.content = calloc(sizeof(int), 1);
            new_vector.content[0] = result;
            new_vector.length = 1;
            new_vector.dtype = NUMERIC;

            $<values>$ = new_vector;
        }
    }
    |
    NUMBER SIDED_DIE NUMBER
    {
        // e.g. 2d20
        vec num_dice;
        num_dice = $<values>1;
        int instances = num_dice.content[0];

        int make_negative = false;
        if (instances == 0){
            vec new_vector;
            new_vector.content = calloc(sizeof(int), instances);
            new_vector.content[0] = 0;
            new_vector.length = 1;
            $<values>$ = new_vector;
        }
        else if (instances < 0){
            make_negative = true;
            instances = instances * -1;
        }


        vec vector;
        vector = $<values>3;

        vec new_vector;
        new_vector.content = calloc(sizeof(int), instances);
        new_vector.length = instances;

        int max = vector.content[0];

        if (max <= 0){
            printf("Cannot roll a dice with a negative amount of sides.");
            YYABORT;
            yyclearin;
        }else if (max > 0){
            for (int i = 0; i!= instances; i++){
                new_vector.content[i] += roll_numeric_die(1, max);
                if (make_negative) new_vector.content[i] *= -1;
            }
        }else{
            for (int i = 0; i!= instances; i++){
                new_vector.content[i] += 0;
            }
        }

        new_vector.dtype = NUMERIC;

        // print_vec(new_vector);

        $<values>$ = new_vector;
    }
    |
    SIDED_DIE NUMBER
    {
        vec vector;
        vector = $<values>2;
        int max = vector.content[0];


        int err = validate_roll(1, max);
        if (err){
            YYABORT;
            yyclearin;
        }else{
            // e.g. d4, it is implied that it is a single dice
            int result = perform_roll(1, max, false, mock_style, mock_constant);

            vec new_vector;
            new_vector.content = calloc(sizeof(int), 1);
            new_vector.content[0] = result;
            new_vector.length = 1;
            new_vector.dtype = NUMERIC;

            $<values>$ = new_vector;
        }
    }
    |
    NUMBER SIDED_DIE MODULO
    {
        vec vector;
        vector = $<values>1;
        int num = vector.content[0];

        int max = 100;

        int err = validate_roll(1, max);
        if (err){
            YYABORT;
            yyclearin;
        }else{
            // e.g. d4, it is implied that it is a single dice
            int result = perform_roll(num, max, false, mock_style, mock_constant);

            vec new_vector;
            new_vector.content = calloc(sizeof(int), 1);
            new_vector.content[0] = result;
            new_vector.length = 1;
            new_vector.dtype = NUMERIC;

            $<values>$ = new_vector;
        }
    }
    |
    SIDED_DIE MODULO
    {
        int max = 100;

        int err = validate_roll(1, max);
        if (err){
            YYABORT;
            yyclearin;
        }else{
            // e.g. d4, it is implied that it is a single dice
            int result = perform_roll(1, max, false, mock_style, mock_constant);

            vec new_vector;
            new_vector.content = calloc(sizeof(int), 1);
            new_vector.content[0] = result;
            new_vector.length = 1;
            new_vector.dtype = NUMERIC;

            $<values>$ = new_vector;
        }
    }
    |
    NUMBER FATE_DIE
    {
        // e.g. dF, it is implied that it is a single dice

        vec vector;
        vector = $<values>2;

        int instances =  $<values>1.content[0];

        vec new_vector;
        new_vector.symbols = calloc(sizeof(char**), instances);
        new_vector.length = instances;
        new_vector.dtype = vector.dtype;

        for (int i = 0; i != instances;i++){
            int idx = roll_symbolic_die(vector.length);
            new_vector.symbols[i] = vector.symbols[idx] ;
        }

        $<values>$ = new_vector;
    }
    |
    FATE_DIE
    {
        // e.g. dF, it is implied that it is a single dice

        vec vector;
        vector = $<values>1;
        int idx = roll_symbolic_die(vector.length);

        vec new_vector;
        new_vector.dtype = vector.dtype;
        new_vector.symbols = calloc(sizeof(char **), 1);
        new_vector.symbols = &vector.symbols[idx];
        new_vector.length = 1;

        $<values>$ = new_vector;
    }
    |
    custom_symbol_dice
    |
    NUMBER
    ;

custom_symbol_dice:
    NUMBER SIDED_DIE SYMBOL_LBRACE csd SYMBOL_RBRACE
    {
        vec num_vector;
        vec vector;
        num_vector = $<values>1;
        vector = $<values>4;
        int idx = roll_symbolic_die(vector.length);
        int instances = num_vector.content[0];


        vec new_vector;
        new_vector.symbols = calloc(sizeof(char**), instances);
        new_vector.length = instances;
        new_vector.dtype = vector.dtype;

        for (int i = 0; i != instances;i++){
            idx = roll_symbolic_die(vector.length);
            new_vector.symbols[i] = vector.symbols[idx] ;
        }

        $<values>$ = new_vector;

    }
    |
    SIDED_DIE SYMBOL_LBRACE csd SYMBOL_RBRACE
    {
        vec vector;
        vector = $<values>3;
        int idx = roll_symbolic_die(vector.length);

        vec new_vector;
        new_vector.dtype = vector.dtype;
        new_vector.symbols = calloc(sizeof(char **), 1);
        new_vector.symbols = &vector.symbols[idx];
        new_vector.length = 1;

        $<values>$ = new_vector;
    }
    |
    MACRO_ACCESSOR CAPITAL_STRING{
        vec vector;
        vector = $<values>2;
        char * name = vector.symbols[0];

        vec new_vector;
        search_macros(name, &new_vector);
        $<values>$ = new_vector;
    }
    ;
csd:
    CAPITAL_STRING SYMBOL_SEPERATOR csd{

        vec l;
        vec r;
        l = $<values>1;
        r = $<values>3;

        vec new_vector;
        new_vector.dtype = l.dtype;
        new_vector.length = l.length + r.length;

        new_vector.symbols = calloc(sizeof(char *), new_vector.length);
        for (int i = 0; i != new_vector.length; i++){
            new_vector.symbols[i] = calloc(sizeof(char), MAX_SYMBOL_TEXT_LENGTH);
        }
        concat_symbols(
            l.symbols, l.length,
            r.symbols, r.length,
            new_vector.symbols
        );
        $<values>$ = new_vector;

    }
    |
    CAPITAL_STRING
    ;


%%
/* Subroutines */

typedef struct yy_buffer_state * YY_BUFFER_STATE;
extern int yyparse();
extern YY_BUFFER_STATE yy_scan_string(char * str);
extern void yy_delete_buffer(YY_BUFFER_STATE buffer);

void reset(){
    mock_style=NO_MOCK;
    mock_return_value = 0;
    mock_constant = 0;
    reset_mocking();
}
int roll(char * s){
    initialize();
    verbose = false;
    YY_BUFFER_STATE buffer = yy_scan_string(s);
    yyparse();

    yy_delete_buffer(buffer);
    return 0;
}
int roll_and_write(char * s, char * f){
    /* Write the result to file. */
    write_to_file = true;
    output_file = f;
    if(verbose) printf("Rolling: %s\n", s);
    return roll(s);
}
int mock_roll(char * s, char * f, int mock_value, bool quiet, int mock_const){
    mock_style = mock_value;
    mock_constant = mock_const;
    mock_return_value = 0;
    verbose = ! quiet;

    return roll_and_write(s, f);
}

char * concat_strings(char ** s, int num_s){
    int size_total = 0;
    bool spaces = false;
    for(int i = 1; i != num_s + 1; i++){
        size_total += strlen(s[i]) + 1;
    }
    if (num_s > 1){
        spaces = true;
        size_total -= 1;  // no need for trailing space
    }
    char * result;
    result = (char *)calloc(sizeof(char), (size_total+1));

    for(int i = 1; i != num_s + 1; i++){
        strcat(result, s[i]);
        if (spaces && i < num_s){
            strcat(result, " ");    // Add spaces
        }
    }

    return result;

}

int main(int argc, char **str){
    char * s = concat_strings(str, argc - 1);
    return roll(s);
}

int yyerror(s)
const char *s;
{
    fprintf(stderr, "%s\n", s);

    if(write_to_file){
        FILE *fp;
        fp = fopen(output_file, "w+");
        fprintf(fp, "%s", s);
        fclose(fp);
    }
    return(1);

}

int yywrap(){
    return (1);
}
