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
