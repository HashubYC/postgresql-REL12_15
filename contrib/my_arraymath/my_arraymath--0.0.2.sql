-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION my_arraymath" to load this file. \quit

-- compare
CREATE OR REPLACE FUNCTION array_compare_value(arr1 ANYARRAY, elt2 ANYELEMENT, op TEXT)
	RETURNS boolean[]
	AS 'MODULE_PATHNAME'
	LANGUAGE 'c'
	IMMUTABLE STRICT;
	
CREATE OR REPLACE FUNCTION array_equals_value(arr1 ANYARRAY, elt2 ANYELEMENT)
	RETURNS boolean[]
	AS 'SELECT array_compare_value($1,$2,''='')'
	LANGUAGE 'sql'
	IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION array_gt_value(arr1 ANYARRAY, elt2 ANYELEMENT)
	RETURNS boolean[]
	AS 'SELECT array_compare_value($1,$2,''>'')'
	LANGUAGE 'sql'
	IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION array_gte_value(arr1 ANYARRAY, elt2 ANYELEMENT)
	RETURNS boolean[]
	AS 'SELECT array_compare_value($1,$2,''>='')'
	LANGUAGE 'sql'
	IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION array_lt_value(arr1 ANYARRAY, elt2 ANYELEMENT)
	RETURNS boolean[]
	AS 'SELECT array_compare_value($1,$2,''<'')'
	LANGUAGE 'sql'
	IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION array_lte_value(arr1 ANYARRAY, elt2 ANYELEMENT)
	RETURNS boolean[]
	AS 'SELECT array_compare_value($1,$2,''<='')'
	LANGUAGE 'sql'
	IMMUTABLE STRICT;

CREATE OPERATOR #= (
    LEFTARG = anyarray, 
    RIGHTARG = anyelement, 
    PROCEDURE = array_equals_value
);

CREATE OPERATOR #> (
    LEFTARG = anyarray, 
    RIGHTARG = anyelement, 
    PROCEDURE = array_gt_value
);

CREATE OPERATOR #>= (
    LEFTARG = anyarray, 
    RIGHTARG = anyelement, 
    PROCEDURE = array_gte_value
);

CREATE OPERATOR #< (
    LEFTARG = anyarray,
    RIGHTARG = anyelement,
    PROCEDURE = array_lt_value
);

CREATE OPERATOR #<= (
    LEFTARG = anyarray,
    RIGHTARG = anyelement,
    PROCEDURE = array_lte_value
);


CREATE OR REPLACE FUNCTION value_equals_array(elt2 ANYELEMENT, arr1 ANYARRAY)
	RETURNS boolean[]
	AS 'SELECT array_compare_value($2,$1,''='')'
	LANGUAGE 'sql'
	IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION value_lt_array(elt2 ANYELEMENT, arr1 ANYARRAY)
	RETURNS boolean[]
	AS 'SELECT array_compare_value($2,$1,''<'')'
	LANGUAGE 'sql'
	IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION value_lte_array(elt2 ANYELEMENT, arr1 ANYARRAY)
	RETURNS boolean[]
	AS 'SELECT array_compare_value($2,$1,''<='')'
	LANGUAGE 'sql'
	IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION value_gt_array(elt2 ANYELEMENT, arr1 ANYARRAY)
	RETURNS boolean[]
	AS 'SELECT array_compare_value($2,$1,''>'')'
	LANGUAGE 'sql'
	IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION value_gte_array(elt2 ANYELEMENT, arr1 ANYARRAY)
	RETURNS boolean[]
	AS 'SELECT array_compare_value($2,$1,''>='')'
	LANGUAGE 'sql'
	IMMUTABLE STRICT;

CREATE OPERATOR #= (
    LEFTARG = anyelement, 
    RIGHTARG = anyarray, 
    PROCEDURE = value_equals_array
);

CREATE OPERATOR #< (
    LEFTARG = anyelement, 
    RIGHTARG = anyarray, 
    PROCEDURE = value_lt_array
);

CREATE OPERATOR #<= (
    LEFTARG = anyelement, 
    RIGHTARG = anyarray, 
    PROCEDURE = value_lte_array
);

CREATE OPERATOR #> (
    LEFTARG = anyelement,
    RIGHTARG = anyarray,
    PROCEDURE = value_gt_array
);

CREATE OPERATOR #>= (
    LEFTARG = anyelement,
    RIGHTARG = anyarray,
    PROCEDURE = value_gte_array
);









-- math
CREATE OR REPLACE FUNCTION array_math_value(arr1 ANYARRAY, elt2 ANYELEMENT, op TEXT)
	RETURNS anyarray
	AS 'MODULE_PATHNAME'
	LANGUAGE 'c'
	IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION array_plus_value(arr1 ANYARRAY, elt2 ANYELEMENT)
	RETURNS anyarray
	AS 'SELECT array_math_value($1,$2,''+'')'
	LANGUAGE 'sql'
	IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION value_plus_array(elt2 ANYELEMENT, arr1 ANYARRAY)
	RETURNS anyarray
	AS 'SELECT array_math_value($2,$1,''+'')'
	LANGUAGE 'sql'
	IMMUTABLE STRICT;

CREATE OPERATOR #+ (
    LEFTARG = anyarray, 
    RIGHTARG = anyelement, 
    PROCEDURE = array_plus_value
);

CREATE OPERATOR #+ (
    LEFTARG = anyelement, 
    RIGHTARG = anyarray, 
    PROCEDURE = value_plus_array
);

CREATE OR REPLACE FUNCTION array_minus_value(arr1 ANYARRAY, elt2 ANYELEMENT)
	RETURNS anyarray
	AS 'SELECT array_math_value($1,$2,''-'')'
	LANGUAGE 'sql'
	IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION value_minus_array(elt2 ANYELEMENT, arr1 ANYARRAY)
	RETURNS anyarray
	AS 'SELECT array_math_value($2,$1,''-'')'
	LANGUAGE 'sql'
	IMMUTABLE STRICT;

CREATE OPERATOR #- (
    LEFTARG = anyarray,
    RIGHTARG = anyelement,
    PROCEDURE = array_minus_value
);

CREATE OPERATOR #- (
    LEFTARG = anyelement,
    RIGHTARG = anyarray,
    PROCEDURE = value_minus_array
);


CREATE OR REPLACE FUNCTION array_times_value(arr1 ANYARRAY, elt2 ANYELEMENT)
	RETURNS anyarray
	AS 'SELECT array_math_value($1,$2,''*'')'
	LANGUAGE 'sql'
	IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION value_times_array(elt2 ANYELEMENT, arr1 ANYARRAY)
	RETURNS anyarray
	AS 'SELECT array_math_value($2,$1,''*'')'
	LANGUAGE 'sql'
	IMMUTABLE STRICT;

CREATE OPERATOR #* (
    LEFTARG = anyarray,
    RIGHTARG = anyelement,
    PROCEDURE = array_times_value
);

CREATE OPERATOR #* (
    LEFTARG = anyelement,
    RIGHTARG = anyarray,
    PROCEDURE = value_times_array
);


CREATE OR REPLACE FUNCTION array_div_value(arr1 ANYARRAY, elt2 ANYELEMENT)
	RETURNS anyarray
	AS 'SELECT array_math_value($1,$2,''/'')'
	LANGUAGE 'sql'
	IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION value_div_array(elt2 ANYELEMENT, arr1 ANYARRAY)
	RETURNS anyarray
	AS 'SELECT array_math_value($2,$1,''/'')'
	LANGUAGE 'sql'
	IMMUTABLE STRICT;

CREATE OPERATOR #/ (
    LEFTARG = anyarray,
    RIGHTARG = anyelement,
    PROCEDURE = array_div_value
);

CREATE OPERATOR #/ (
    LEFTARG = anyelement,
    RIGHTARG = anyarray,
    PROCEDURE = value_div_array
);



-- update
CREATE OR REPLACE FUNCTION array_min(arr anyarray)
	RETURNS ANYELEMENT
	AS 'MODULE_PATHNAME'
	LANGUAGE 'c'
	IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION array_max(arr anyarray)
	RETURNS ANYELEMENT
	AS 'MODULE_PATHNAME'
	LANGUAGE 'c'
	IMMUTABLE STRICT;
