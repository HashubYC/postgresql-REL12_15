#include "postgres.h"
#include "fmgr.h"

// #include "utils/builtins.h"

#if PG_VERSION_NUM < 130000
#include <access/tuptoaster.h>
#else
#include <access/detoast.h>
#endif

#include <catalog/namespace.h>
#include <catalog/pg_operator.h>
#include <catalog/pg_type.h>
#include <utils/array.h>
#include <utils/builtins.h>
#include <utils/syscache.h>
#include <utils/typcache.h>


/* Set up PgSQL */
PG_MODULE_MAGIC;

static ArrayIterator
arraymath_create_iterator(ArrayType *arr)
{
#if PG_VERSION_NUM >= 90500
    return array_create_iterator(arr, 0, NULL);
#else
    return array_create_iterator(arr, 0);
#endif
}

/*
 * 给定一个运算符符号("+"、"-"、"="、">"等) 和 元素类型，尝试查找适当的函数来执行该类型的运算。
 */
static void
arraymath_fmgrinfo_from_optype(const char *opstr, Oid element_type1,
                               Oid element_type2, FmgrInfo *operfmgrinfo, Oid *return_type)
{
    Oid operator_oid;
    HeapTuple opertup;
    Form_pg_operator operform;

    // 查找与符号和数据类型的组合相对应的操作符Oid
    operator_oid = OpernameGetOprid(list_make1(makeString(pstrdup(opstr))), element_type1, element_type2);
    if (!(operator_oid && OperatorIsVisible(operator_oid)))
    {
        elog(ERROR, "operator does not exist");
    }

    /* 查找与操作符Oid相关联的函数 */
    opertup = SearchSysCache1(OPEROID, ObjectIdGetDatum(operator_oid)); // opertup 是 HeapTuple 
    if (!HeapTupleIsValid(opertup))
    {
        elog(ERROR, "cannot find operator heap tuple");
    }

    operform = (Form_pg_operator)GETSTRUCT(opertup);
    *return_type = operform->oprresult;

    fmgr_info(operform->oprcode, operfmgrinfo);
    ReleaseSysCache(opertup);

    return;
}

/*
 * Read type information for a given element type.
 * 读取给定元素类型的类型信息。
 */
static TypeCacheEntry *
arraymath_typentry_from_type(Oid element_type, int flags)
{
    TypeCacheEntry *typentry;
    typentry = lookup_type_cache(element_type, flags);
    if (!typentry)
    {
        elog(ERROR, "unable to lookup element type info for %s",
             format_type_be(element_type));
    }
    return typentry;
}

/*
 * 对数组中的所有元素应用运算符。
 */
static ArrayType *
arraymath_array_oper_elem(ArrayType *array1, const char *opname, Datum element2, Oid element_type2)
{
    ArrayType *array_out;
    int dims[1];
    int lbs[1];
    Datum *elems;
    bool *nulls;

    int ndims1 = ARR_NDIM(array1); // 获取数组维度
    int *dims1 = ARR_DIMS(array1);
    Oid element_type1 = ARR_ELEMTYPE(array1); // 获取数组元素类型
    Oid rtype;
    int nelems, n = 0;
    FmgrInfo operfmgrinfo;
    TypeCacheEntry *tinfo;
    ArrayIterator iterator1;
    Datum element1;
    bool isnull1;

    if (ndims1 != 1) // 判断数组维度是否 1
    {
        elog(ERROR, "only one-dimensional arrays are supported");
        return NULL;
    }

    /* 哪个函数适用于这些输入类型? */
    /* 输出数组的数据类型是什么? */
    // fn_oid operfmgrinfo= FmgrInfo
    arraymath_fmgrinfo_from_optype(opname, element_type1, element_type2, &operfmgrinfo, &rtype);

    /* 输出数组大小? */
    nelems = ArrayGetNItems(ndims1, dims1);

    /* If input is empty, return empty */
    if (nelems == 0)
    {
        return construct_empty_array(rtype);
    }

    iterator1 = arraymath_create_iterator(array1);

    /* 为输出数据分配空间 */
    elems = palloc(sizeof(Datum) * nelems);
    nulls = palloc(sizeof(bool) * nelems);

    while (array_iterate(iterator1, &element1, &isnull1))
    {
        if (isnull1)
        {
            nulls[n] = true;
            elems[n] = (Datum)0;
        }
        else
        {
            /* 应用运算符 */
            nulls[n] = false;
            elems[n] = FunctionCall2(&operfmgrinfo, element1, element2); // int4ge(element1 >= element2)
        }
        n++;
    }

    /* 构建一维输出数组 */
    tinfo = arraymath_typentry_from_type(rtype, 0);
    dims[0] = nelems;
    lbs[0] = 1;
    array_out = construct_md_array(elems, nulls, 1, dims, lbs, rtype, tinfo->typlen, tinfo->typbyval, tinfo->typalign);

    /* 输出应该是一个副本，所以释放 elems */
    pfree(elems);
    pfree(nulls);

    /* Make sure we haven't been given garbage */
    if (!array_out)
    {
        elog(ERROR, "unable to construct output array");
        return NULL;
    }

    return array_out;
}

/*
 * Compare an array to a constant element
 */
PG_FUNCTION_INFO_V1(array_compare_value);
Datum array_compare_value(PG_FUNCTION_ARGS)
{
    ArrayType *array1 = PG_GETARG_ARRAYTYPE_P(0);

    Datum element2 = PG_GETARG_DATUM(1);
    text *operator= PG_GETARG_TEXT_P(2);
    char *opname = text_to_cstring(operator);
    Oid element_type2;
    ArrayType *arrayout;

    element_type2 = get_fn_expr_argtype(fcinfo->flinfo, 1);
    arrayout = arraymath_array_oper_elem(array1, opname, element2, element_type2);

    PG_FREE_IF_COPY(array1, 0);
    PG_RETURN_ARRAYTYPE_P(arrayout);
}

/*
 * Do math on an array using a constant element
 */
PG_FUNCTION_INFO_V1(array_math_value);
Datum array_math_value(PG_FUNCTION_ARGS)
{
    ArrayType *array1 = PG_GETARG_ARRAYTYPE_P(0);
    Datum element2 = PG_GETARG_DATUM(1);
    text *operator= PG_GETARG_TEXT_P(2);
    char *opname = text_to_cstring(operator);
    Oid element_type2;
    ArrayType *arrayout;

    element_type2 = get_fn_expr_argtype(fcinfo->flinfo, 1);
    arrayout = arraymath_array_oper_elem(array1, opname, element2, element_type2);

    PG_FREE_IF_COPY(array1, 0);
    PG_RETURN_ARRAYTYPE_P(arrayout);
}









// update

static void
arraymath_check_type(Oid elmtype)
{
    /* Initialize result value */
    if (elmtype != INT2OID &&
        elmtype != INT4OID &&
        elmtype != INT8OID &&
        elmtype != FLOAT4OID &&
        elmtype != FLOAT8OID &&
        elmtype != NUMERICOID)
    {
        ereport(ERROR, (
                           errmsg(
                               "Array type must be NUMERIC, SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION")));
    }
}

static Datum
arraymath_minmax(ArrayType *arr, int mode)
{
    Oid arrType = ARR_ELEMTYPE(arr);
    Datum elem, result = (Datum)0, cmp;
    bool isnull, first = true;
    TypeCacheEntry *typeCache = arraymath_typentry_from_type(arrType, TYPECACHE_CMP_PROC_FINFO);
    FmgrInfo cmpFmgrInfo = typeCache->cmp_proc_finfo;
    ArrayIterator iterator;

    arraymath_check_type(arrType);

    iterator = arraymath_create_iterator(arr);
    while (array_iterate(iterator, &elem, &isnull))
    {
        if (isnull)
            continue;

        if (first)
        {
            result = elem;
            first = false;
            continue;
        }

        /* cmp_proc_finfo returns -1 for less than */
        /* and 1 for greater than. Mode is -1 for min */
        /* and 1 for max */
        cmp = FunctionCall2(&cmpFmgrInfo, elem, result);
        if ((mode < 0 && DatumGetInt32(cmp) < 0) ||
            (mode > 0 && DatumGetInt32(cmp) > 0))
        {
            result = elem;
        }
    }
    return result;
}

/*
 * Do minimum of an array
 */
PG_FUNCTION_INFO_V1(array_min);
Datum array_min(PG_FUNCTION_ARGS)
{
    ArrayType *arr = PG_GETARG_ARRAYTYPE_P(0);
    size_t arrLen;

    if (ARR_NDIM(arr) == 0)
        PG_RETURN_NULL();

    if (ARR_NDIM(arr) > 1)
        ereport(ERROR, (errmsg("only one-dimensional arrays are supported")));

    arrLen = (ARR_DIMS(arr))[0];
    if (arrLen == 0)
        PG_RETURN_NULL();

    PG_RETURN_DATUM(arraymath_minmax(arr, -1));
}

/*
 * Do maximum of an array
 */
PG_FUNCTION_INFO_V1(array_max);
Datum array_max(PG_FUNCTION_ARGS)
{
    ArrayType *arr = PG_GETARG_ARRAYTYPE_P(0);
    size_t arrLen;

    if (ARR_NDIM(arr) == 0)
        PG_RETURN_NULL();

    if (ARR_NDIM(arr) > 1)
        ereport(ERROR, (errmsg("only one-dimensional arrays are supported")));

    arrLen = (ARR_DIMS(arr))[0];
    if (arrLen == 0)
        PG_RETURN_NULL();

    PG_RETURN_DATUM(arraymath_minmax(arr, 1));
}
