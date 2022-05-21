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
#include "rolls/sided_dice.h"

#define UNUSED(x) (void)(x)

int yylex(void);
int yyerror(const char* s);
void print_err_if_present(int err_code);

int yydebug=1;
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
    return random_fn(small, big);
}
int roll_symbolic_die(int length_of_symbolic_array){
    // Returns random index into symbolic array
    return roll_numeric_die(0, length_of_symbolic_array -1);
}


%}


%start dicetower_statement

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

dicetower_statement:
    macro_statement dice_statement
    |
    dice_statement
;
macro_statement:
    MACRO_STORAGE CAPITAL_STRING ASSIGNMENT custom_symbol_dice MACRO_SEPERATOR {
        vec key = $<values>2;
        vec value = $<values>4;

        register_macro(key.symbols[0], &value);
    }
;

dice_statement: math{
    vec vector;
    vec new_vec;
    vector = $<values>1;

    new_vec = vector;
    //  Step 1: Collapse pool to a single value if nessicary
    collapse_vector(&vector, &new_vec);

    // Step 2: Output
    FILE *fp;

    if(write_to_file){
        fp = fopen(output_file, "w+");
    }

    for(int i = 0; i!= new_vec.length;i++){
        if (new_vec.dtype == SYMBOLIC){
            // TODO: Strings >1 character
            if (verbose){
                printf("%s", new_vec.symbols[i]);
            }
            if(write_to_file){
                fprintf(fp, "%s", new_vec.symbols[i]);
            }
        }else{
            if(verbose){
                printf("%d", new_vec.content[i]);
            }
            if(write_to_file){
                fprintf(fp, "%d", new_vec.content[i]);
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
    dice_operations
;


dice_operations:

    die_roll REROLL_IF EQ NUMBER{

        vec die_vector = $<values>1;
        vec num_vector = $<values>4;

        // TODO: Set-Based Equals.
        // TODO: Symbolic Dice
        // TODO: All Dice Rolls

        printf("Warn: Only partial reroll support at present.");
        if (die_vector.dtype == SYMBOLIC){
            printf("Symbolic Dice not supported in reroll logic yet\n");
            YYABORT;
            yyclearin;
        }else{
            if (die_vector.content[0] == num_vector.content[0]){
                roll_params rp = die_vector.source;
                int * result = do_roll(rp);
                die_vector.content = result;            
            }else{
                // N.Eq.
            }
        }
        $<values>$ = die_vector;
    }
    |
    die_roll KEEP_HIGHEST NUMBER
    {
        vec roll_vector = $<values>1;
        vec keep_vector = $<values>3;
        vec new_vec;
        unsigned int num_to_hold = keep_vector.content[0];

        unsigned int err = keep_highest_values(&roll_vector, &new_vec, num_to_hold);

        if(err){
            printf("Error in: KeepHighestN.");
            YYABORT;
            yyclearin;
        }
        $<values>$ = new_vec;
    }
    |
    die_roll KEEP_LOWEST NUMBER
    {
        vec roll_vector;
        vec keep_vector;
        unsigned int num_to_hold;
        roll_vector = $<values>1;
        keep_vector = $<values>3;
        num_to_hold = keep_vector.content[0];

        vec new_vec;
        unsigned int err = keep_lowest_values(&roll_vector, &new_vec, num_to_hold);

        if(err){
            printf("Error in: KeepLowestN.");
            YYABORT;
            yyclearin;
        }
        $<values>$ = new_vec;
    }
    |
    die_roll KEEP_HIGHEST
    {
        vec roll_vector;
        unsigned int num_to_hold;
        roll_vector = $<values>1;
        num_to_hold = 1;

        vec new_vec;
        unsigned int err = keep_highest_values(&roll_vector, &new_vec, num_to_hold);

        if(err){
            printf("Error in: KeepHighest1.");
            YYABORT;
            yyclearin;
        }
        $<values>$ = new_vec;
    }
    |
    die_roll KEEP_LOWEST
    {
        vec roll_vector;
        unsigned int num_to_hold;
        roll_vector = $<values>1;
        num_to_hold = 1;

        vec new_vec;
        unsigned int err = keep_lowest_values(&roll_vector, &new_vec, num_to_hold);

        if(err){
            printf("Error in: KeepHighest1.");
            YYABORT;
            yyclearin;
        }
        $<values>$ = new_vec;
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
            // Collapse if Nessicary
            if(vector.length > 1){
                int result = sum(vector.content, vector.length);

                vec new_vector;
                initialize_vector(&new_vector, NUMERIC, 1);
                new_vector.content[0] = sum(vector.content, vector.length);

                $<values>$ = new_vector;
            }else{
                $<values>$ = vector;
            }

        }
     } 
;

die_roll:
   NUMBER SIDED_DIE NUMBER EXPLOSION
    {
        
        vec number_of_dice;
        initialize_vector(&number_of_dice, NUMERIC, 1);
        number_of_dice.content[0] = 1;

        int err = roll_plain_sided_dice(
            &$<values>1,
            &$<values>3,
            &$<values>$,
            true
        );
        print_err_if_present(err);
        if(err){
            YYABORT;
            yyclearin;
        }
    }
    |
    SIDED_DIE NUMBER EXPLOSION
    {

        vec number_of_dice;
        initialize_vector(&number_of_dice, NUMERIC, 1);
        number_of_dice.content[0] = 1;

        int err = roll_plain_sided_dice(
            &number_of_dice,
            &$<values>2,
            &$<values>$,
            true
        );
        print_err_if_present(err);
        if(err){
            YYABORT;
            yyclearin;
        }

    }
    |
    NUMBER SIDED_DIE NUMBER
    {
        
        vec number_of_dice;
        initialize_vector(&number_of_dice, NUMERIC, 1);
        number_of_dice.content[0] = 1;

        int err = roll_plain_sided_dice(
            &$<values>1,
            &$<values>3,
            &$<values>$,
            false
        );
        print_err_if_present(err);
        if(err){
            YYABORT;
            yyclearin;
        }
    }
    |
    SIDED_DIE NUMBER
    {
        vec number_of_dice;
        initialize_vector(&number_of_dice, NUMERIC, 1);
        number_of_dice.content[0] = 1;

        int err = roll_plain_sided_dice(
            &number_of_dice,
            &$<values>2,
            &$<values>$,
            false
        );
        print_err_if_present(err);
        if(err){
            YYABORT;
            yyclearin;
        }
    }
    |
    NUMBER SIDED_DIE MODULO
    {
        vec dice_sides;
        initialize_vector(&dice_sides, NUMERIC, 1);
        dice_sides.content[0] = 100;

        int err = roll_plain_sided_dice(
            &$<values>1,
            &dice_sides,
            &$<values>$,
            false
        );
        print_err_if_present(err);
        if(err){
            YYABORT;
            yyclearin;
        }

    }
    |
    SIDED_DIE MODULO
    {
       
        vec num_dice;
        initialize_vector(&num_dice, NUMERIC, 1);
        num_dice.content[0] = 1;
        vec dice_sides;
        initialize_vector(&dice_sides, NUMERIC, 1);
        dice_sides.content[0] = 100;

        int err = roll_plain_sided_dice(
            &num_dice,
            &dice_sides,
            &$<values>$,
            false
        );
        print_err_if_present(err);
        if(err){
            YYABORT;
            yyclearin;
        }

    }
    |
    NUMBER FATE_DIE
    {
        vec result_vec;
        initialize_vector(&result_vec, SYMBOLIC, $<values>1.content[0]);

        int err = roll_symbolic_dice(
            &$<values>1,
            &$<values>2,
            &result_vec
        );
        $<values>$ = result_vec;
        print_err_if_present(err);
        if(err){
            YYABORT;
            yyclearin;
        }

    }
    |
    FATE_DIE
    {
        vec result_vec;
        vec number_of_dice;
        initialize_vector(&result_vec, SYMBOLIC, 1);
        initialize_vector(&number_of_dice, NUMERIC, 1);
        number_of_dice.content[0] = 1;

        int err = roll_symbolic_dice(
            &number_of_dice,
            &$<values>1,
            &result_vec
        );
        $<values>$ = result_vec;
        print_err_if_present(err);
        if(err){
            YYABORT;
            yyclearin;
        }      
    }
    |
    custom_symbol_dice
    |
    NUMBER
    ;

custom_symbol_dice:
    NUMBER SIDED_DIE SYMBOL_LBRACE csd SYMBOL_RBRACE
    {
        vec result_vec;
        initialize_vector(&result_vec, SYMBOLIC, $<values>1.content[0]);

        int err = roll_symbolic_dice(
            &$<values>1,
            &$<values>4,
            &result_vec
        );
        $<values>$ = result_vec;
        print_err_if_present(err);
        if(err){
            YYABORT;
            yyclearin;
        }
    }
    |
    SIDED_DIE SYMBOL_LBRACE csd SYMBOL_RBRACE
    {
        
        vec result_vec;
        vec number_of_dice;
        initialize_vector(&result_vec, SYMBOLIC, 1);
        initialize_vector(&number_of_dice, NUMERIC, 1);
        number_of_dice.content[0] = 1;

        int err = roll_symbolic_dice(
            &number_of_dice,
            &$<values>3,
            &result_vec
        );
        $<values>$ = result_vec;
        print_err_if_present(err);
        if(err){
            YYABORT;
            yyclearin;
        }
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
    init_mocking(mock_value, mock_const);
    verbose = !quiet;
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
void print_err_if_present(int err_code){
    switch(err_code){
        case 1:{
            printf("Negative Dice Sides not Allowed\n");
            break;
        }
    }
}