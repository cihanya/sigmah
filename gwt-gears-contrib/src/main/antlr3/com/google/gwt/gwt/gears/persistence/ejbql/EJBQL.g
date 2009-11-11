grammar EJBQL;

@header {
package com.google.gwt.gears.persistence.ejbql
}

// Alexander Kunkel
// More JPA informations:
// http://www.kunkelgmbh.de/jpa/jpa.html

ql_statement
	: select_statement
	| update_statement
	| delete_statement;

select_statement
	: select_clause from_clause (where_clause)? (groupby_clause)? (having_clause)?(orderby_clause)?;

update_statement
	: update_clause (where_clause)?	;

delete_statement
	: delete_clause (where_clause)?	;

from_clause
	: 'FROM' identification_variable_declaration (','(identification_variable_declaration|collection_member_declaration))*;

identification_variable_declaration
	: range_variable_declaration ( join | fetch_join )*;

range_variable_declaration
	: abstract_schema_name ('AS')? identification_variable;

join
	: join_spec join_association_path_expression ('AS')? identification_variable;

fetch_join
	: join_spec 'FETCH' join_association_path_expression;

join_spec
	:(('LEFT')? ('OUTER')? | 'INNER' )? 'JOIN';

join_association_path_expression
	: join_collection_valued_path_expression
	| join_single_valued_association_path_expression;

join_collection_valued_path_expression
	: identification_variable '.' collection_valued_association_field;

join_single_valued_association_path_expression
	: identification_variable '.' single_valued_association_field;

collection_member_declaration
	: 'IN''(' collection_valued_path_expression ')' ('AS')? identification_variable;

single_valued_path_expression
	: state_field_path_expression | single_valued_association_path_expression;

state_field_path_expression
	: (identification_variable | single_valued_association_path_expression) '.' state_field;

single_valued_association_path_expression
	: identification_variable '.' (single_valued_association_field'.')* single_valued_association_field;

collection_valued_path_expression
	: identification_variable '.' (single_valued_association_field '.')* collection_valued_association_field;

state_field
	: (embedded_class_state_field '.')* simple_state_field;

update_clause
	: 'UPDATE' abstract_schema_name (('AS')? identification_variable)? 'SET' update_item (',' update_item)*;

update_item
	: (identification_variable'.')?(state_field | single_valued_association_field) '=' new_value;

new_value
	: simple_arithmetic_expression
	| string_primary
	| datetime_primary
	| boolean_primary
	| enum_primary
	| simple_entity_expression
	| 'NULL';

delete_clause
	: 'DELETE' 'FROM' abstract_schema_name (('AS')? identification_variable)?;

select_clause
	: 'SELECT' ('DISTINCT')? select_expression (',' select_expression)*;

select_expression
	: single_valued_path_expression
	| aggregate_expression
	| identification_variable
	| 'OBJECT' '('identification_variable')'
	| constructor_expression;

constructor_expression
	: 'NEW' constructor_name '(' constructor_item (',' constructor_item)* ')';

constructor_item
	: single_valued_path_expression | aggregate_expression;

aggregate_expression
	: ( 'AVG' | 'MAX' | 'MIN' |'SUM' ) '(' ('DISTINCT')? state_field_path_expression')'
	| 'COUNT' '(' ('DISTINCT')? (identification_variable | state_field_path_expression | single_valued_association_path_expression) ')';

where_clause
	: 'WHERE' conditional_expression;

groupby_clause
	: 'GROUP' 'BY' groupby_item (',' groupby_item)*;

groupby_item
	: single_valued_path_expression | identification_variable;

having_clause
	: 'HAVING' conditional_expression;

orderby_clause
	: 'ORDER' 'BY' orderby_item (',' orderby_item)*;

orderby_item
	: state_field_path_expression	('ASC' | 'DESC')?;

subquery
	: simple_select_clause subquery_from_clause (where_clause)? (groupby_clause)? (having_clause)?;

subquery_from_clause
	: 'FROM' subselect_identification_variable_declaration (',' subselect_identification_variable_declaration)*;

subselect_identification_variable_declaration
	: identification_variable_declaration
	| association_path_expression ('AS')? identification_variable
	| collection_member_declaration;

association_path_expression
	: collection_valued_path_expression
  | single_valued_association_path_expression;

simple_select_clause
	: 'SELECT' ('DISTINCT')? simple_select_expression;

simple_select_expression
	: single_valued_path_expression
	| aggregate_expression
	| identification_variable;

conditional_expression
	: conditional_term
	| conditional_expression 'OR' conditional_term;

conditional_term
	: conditional_factor
	| conditional_term 'AND' conditional_factor;

conditional_factor
	: ('NOT')? conditional_primary;

conditional_primary
	: simple_cond_expression | '('conditional_expression')';

simple_cond_expression
	: comparison_expression
	| between_expression
	| like_expression
	| in_expression
	| null_comparison_expression
	| empty_collection_comparison_expression
	| collection_member_expression
	| exists_expression;

between_expression
	: arithmetic_expression ('NOT')? 'BETWEEN' arithmetic_expression 'AND' arithmetic_expression
	| string_expression ('NOT')? 'BETWEEN' string_expression 'AND' string_expression
	| datetime_expression ('NOT')? 'BETWEEN' datetime_expression 'AND' datetime_expression;

in_expression
	: state_field_path_expression ('NOT')? 'IN' '(' (in_item (',' in_item)*
	| subquery) ')';

in_item
	: literal
	| input_parameter;

like_expression
	: string_expression ('NOT')? 'LIKE' pattern_value ('ESCAPE' escape_character)?;

null_comparison_expression
	: (single_valued_path_expression | input_parameter) 'IS' ('NOT')? 'NULL';

empty_collection_comparison_expression
	: collection_valued_path_expression 'IS' ('NOT')? 'EMPTY';

collection_member_expression
	: entity_expression ('NOT')? 'MEMBER' ('OF')? collection_valued_path_expression;

exists_expression
	: ('NOT')? 'EXISTS' '('subquery')';

all_or_any_expression
	: ( 'ALL' | 'ANY' | 'SOME') '('subquery')';

comparison_expression
	: string_expression comparison_operator (string_expression | all_or_any_expression)
	| boolean_expression ('=' | '<>') (boolean_expression
	| all_or_any_expression)
	| enum_expression ('='|'<>') (enum_expression | all_or_any_expression)
	| datetime_expression comparison_operator (datetime_expression | all_or_any_expression)
	| entity_expression ('=' | '<>') (entity_expression | all_or_any_expression)
	| arithmetic_expression comparison_operator (arithmetic_expression | all_or_any_expression);

comparison_operator
	: '='
	| '>'
	| '>='
	| '<'
	| '<='
	| '<>';

arithmetic_expression
	: simple_arithmetic_expression
	| '('subquery')';

simple_arithmetic_expression
	: arithmetic_term
	| simple_arithmetic_expression ( '+' | '-' ) arithmetic_term;

arithmetic_term
	: arithmetic_factor
	| arithmetic_term ( '*' | '/' ) arithmetic_factor;

arithmetic_factor
	: ( '+' | '-' )? arithmetic_primary;

arithmetic_primary
	: state_field_path_expression
	| numeric_literal
	| '('simple_arithmetic_expression')'
	| input_parameter
	| functions_returning_numerics
	| aggregate_expression;

string_expression
	: string_primary | '('subquery')';

string_primary
	: state_field_path_expression
	| string_literal
	| input_parameter
	| functions_returning_strings
	| aggregate_expression;

datetime_expression
	: datetime_primary
	| '('subquery')';

datetime_primary
	: state_field_path_expression
	| input_parameter
	| functions_returning_datetime
	| aggregate_expression;

boolean_expression
	: boolean_primary
	| '('subquery')';

boolean_primary
	: state_field_path_expression
	| boolean_literal
	| input_parameter;

enum_expression
	: enum_primary
	| '('subquery')';

enum_primary
	: state_field_path_expression
	| enum_literal
	| input_parameter;

entity_expression
	: single_valued_association_path_expression
	| simple_entity_expression;

simple_entity_expression
	: identification_variable
	| input_parameter;

functions_returning_numerics
	: 'LENGTH' '('string_primary')'
	| 'LOCATE' '('string_primary',' string_primary(',' simple_arithmetic_expression)?')'
	| 'ABS' '('simple_arithmetic_expression')'
	| 'SQRT' '('simple_arithmetic_expression')'
	| 'MOD' '('simple_arithmetic_expression',' simple_arithmetic_expression')'
	| 'SIZE' '('collection_valued_path_expression')';

functions_returning_datetime
	: 'CURRENT_DATE'
	| 'CURRENT_TIME'
	| 'CURRENT_TIMESTAMP';

functions_returning_strings
	: 'CONCAT' '('string_primary',' string_primary')'
	| 'SUBSTRING' '('string_primary','simple_arithmetic_expression',' simple_arithmetic_expression')'
	| 'TRIM' '('((trim_specification)? (trim_character)? 'FROM')? string_primary')'
	| 'LOWER' '('string_primary')'
	| 'UPPER' '('string_primary')';

trim_specification
	: 'LEADING'
	| 'TRAILING'
	| 'BOTH';










trim_character
	:	;

numeric_literal
	:	;

escape_character
	:	;

pattern_value
	:	;

input_parameter
	:	;

literal
	:	;

constructor_name
	:	;

enum_literal
	:	;

boolean_literal
	:	;

string_literal
	:	;

simple_state_field
	:	;

embedded_class_state_field
	:	;

single_valued_association_field
	:	;

collection_valued_association_field
	:	;

identification_variable
	:	;
abstract_schema_name
	:	;