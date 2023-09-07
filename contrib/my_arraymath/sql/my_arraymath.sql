CREATE EXTENSION my_arraymath;

-- compare
SELECT ARRAY[1,2,3,4] #= 3;
SELECT ARRAY[1,2,3,4] #< 3;
SELECT ARRAY[1,2,3,4] #<= 3;
SELECT ARRAY[1,2,3,4] #> 3;
SELECT ARRAY[1,2,3,4] #>= 3;

SELECT 3 #= ARRAY[1,2,3,4];
SELECT 3 #< ARRAY[1,2,3,4];
SELECT 3 #<= ARRAY[1,2,3,4];
SELECT 3 #> ARRAY[1,2,3,4];
SELECT 3 #>= ARRAY[1,2,3,4];


-- math
SELECT ARRAY[1,2,3,4,5] #+ 2;
SELECT ARRAY[1,2,3,4,5] #- 2;
SELECT ARRAY[1,2,3,4,5] #* 2;
SELECT ARRAY[1,2,3,4,5] #/ 2;

SELECT 2 #+ ARRAY[1,2,3,4,5];
SELECT 2 #- ARRAY[1,2,3,4,5];
SELECT 2 #* ARRAY[1,2,3,4,5];
SELECT 2 #/ ARRAY[1,2,3,4,5];


SELECT ARRAY[3.4,5.6,7.6] #* 8.1;



SELECT ARRAY[1,2,3,4,5] #> ARRAY[1,2];



-- -- update
select array_min(ARRAY[1,2,3]);
select array_min(ARRAY[5.1,2.2,3,10]);

select array_max(ARRAY[5,2,3,9]);
select array_max(ARRAY[5,2,3,9.1]);

