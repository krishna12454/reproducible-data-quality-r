


/*
 Authors 
 Martin Schlather, schlather@math.uni-mannheim.de


 Copyright (C) 2015 -- 2021 Martin Schlather

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 3
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.  
*/

#ifndef rfutils_init_H
#define rfutils_init_H 1


 /* 
!!!!! HIER NIE EIN SEXP OBJEKT ZURUECKGEBEN  !!!!  
  */

// #include "Utils.h"
#include "options.h"


#ifdef HAVE_VISIBILITY_ATTRIBUTE
  # define attribute_hidden __attribute__ ((visibility ("hidden")))
#else
  # define attribute_hidden
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define MY_PACKAGE "RandomFieldsUtils"
  //#define MY_ACRONYM XX
#include "zzz_calls.h"

  /* 
!!!!! HIER NIE EIN SEXP OBJEKT ZURUECKGEBEN  !!!!  
!!!!! auch kein mit MALLOC kreiertes Objekt  !!!!
  */

#define AttachMessageN 2000
#define LEN_OPTIONNAME 201 // zwingend ungerade
typedef void (*setoptions_fctn) (int, int, SEXP, char[LEN_OPTIONNAME],
				 bool, bool);
typedef void (*getoptions_fctn) (SEXP, int, bool);
typedef void (*finalsetoptions_fctn) (int);
typedef void (*deleteoptions_fctn) (bool);

  
#define MATERN_NU_THRES 100
#define BESSEL_NU_THRES 100
#define LOW_MATERN 1e-20
#define LOW_BESSEL 1e-20

  DECLARE1(void, del_utilsoption, utilsoption_type * S)
#define PIVOT_IDX_N 0
#define  N_UTILS_PARAM (PIVOT_IDX_N + 1)
  DECLARE2(void, params_utilsoption,  int local, int * params)
  DECLARE2(void, get_utilsoption, utilsoption_type * S, int local)
  DECLARE2(void, push_utilsoption, utilsoption_type * S, int local)
   
  DECLARE1(void, solve_DELETE, solve_storage** S)
  DECLARE1(void, solve_NULL, solve_storage* x)
  DECLARE3(int, sqrtRHS, solve_storage * pt, double* RHS, double * res)
  DECLARE2(double, StruveH, double x, double nu)
  DECLARE3(double, StruveL, double x, double nu, bool expScale1d)
  DECLARE1(double, I0mL0, double x)
  DECLARE3(double, WM, double x, double nu, double factor)
  DECLARE3(double, DWM, double x, double nu, double factor)
  DECLARE3(double, DDWM, double x, double nu, double factor)
  DECLARE3(double, D3WM, double x, double nu, double factor)
  DECLARE3(double, D4WM, double x, double nu, double factor)
  DECLARE4(double, logWM, double x, double nu1, double nu2, double factor)
  DECLARE1(double, Gauss, double x)
  DECLARE1(double, DGauss, double x)
  DECLARE1(double, DDGauss, double x)
  DECLARE1(double, D3Gauss, double x)
  DECLARE1(double, D4Gauss, double x)
  DECLARE1(double, logGauss, double x)
  DECLARE0(int, cores1)
  DECLARE0(int, cpus)
  
  DECLARE2(void, detachRFUoptions, const char ** prefixlist, int N)
  DECLARE18(void, attachRFUoptions, char * name,
	    const char ** prefixlist, int N, 
	    const char *** all, int * allN, setoptions_fctn set,
	    getoptions_fctn get,
	    finalsetoptions_fctn final,
	    deleteoptions_fctn del,
	    setoptions_fctn setRFU, getoptions_fctn getRFU,
	    int pl_offset, bool basicopt,
	    install_modes gpu_needs, Uint avx_info, int version,
	    int RFUversion, int mem_is_aligned)
  DECLARE4(void, attachSetNGet, char*calling,
	   char *pkgname, setoptions_fctn set,
	   getoptions_fctn get)
  DECLARE2(SEXP, RFUoptions, SEXP options, char * calling)
  DECLARE3(void, getoptionsRFU, SEXP sublist, int i, utilsoption_type *options)
  DECLARE6(void, setoptionsRFU, int i, int j, SEXP el,
	   char name[LEN_OPTIONNAME], bool isList, utilsoption_type *options) 


  DECLARE3(void, sorting, double* data, int len, usr_bool NAlast)
  DECLARE3(void, sortingL, double* data, Long len, usr_bool NAlast)
  DECLARE3(void, sortingInt, int* data, int len, usr_bool NAlast)
  DECLARE3(void, sortingLong, Long* data, Long len, usr_bool NAlast)
  DECLARE4(void, ordering, double* data, int len, int dim, int * pos)
  DECLARE4(void, orderingL, double* data, Long len, int dim, Long * pos)
  DECLARE4(void, orderingInt, int* data, int len, int dim, int * pos)
  DECLARE4(void, orderingLong, Long* data, Long len, int dim, Long * pos)

    DECLARE4(double, scalarX, double * x, double * y, Long len, Long n)
  //  DECLARE4(int, scalarInt, int * x, int * y, int len, int n)
  DECLARE2(void, chol2inv, double * MPT, int size)
  DECLARE1(void, pid, int * i)
  DECLARE0(bool, parallel)
  DECLARE1(void, sleepMicro, int * i)
  // DECLARE7(int, cholGPU, bool copy, double* M, int size, double* rhs, int rhs_cols, double * LogDet, double * RESULT); // entkommentieren


  DECLARE9(int, xCinvXdet,double* M, int size, double *X, Long X_cols,
	   double * XCinvX, double * det, bool log, solve_storage *PT,
	   int cores)
  DECLARE11(int, xCinvYdet,double* M, int size, bool posdef,
	    double * X, double * Y, Long cols,
	    double * XCinvY, double * det, bool log, solve_storage *PT,
	    int cores)
  DECLARE3(int, cholesky, double * MPT, int size, int cores)
  DECLARE8(int, SolvePosDef, double* M, int size, bool posdef, 
	   double * rhs, Long rhs_cols, double * logdet, solve_storage * PT,
	   int cores)
  DECLARE9(int, SolvePosDefSp, double * M, int size, bool posdef,
	   double * rhs, Long rhs_cols, double *logdet,
	   solve_storage * Pt, solve_options *sp, int cores)
  DECLARE5(int, SqrtPosDefFree, double * M, int size, solve_storage * pt,
	   solve_options * sp, int cores)
  DECLARE4(double, DetPosDefsp, double * M, int size, solve_options * sp,
	   int cores)
  DECLARE3(int, InvertMatrix, double * M, int size, int cores)
  DECLARE3(double, DetPosDef, double * M,  int size, int cores) // destroys M!
  DECLARE3(bool, Is_positive_definite, double * C, int  dim, int cores)

  
#if defined OBSOLETE_RFU
  #undef AttachMessageN
  typedef void (*setparameterfct) (int, int, SEXP, char[200], bool, int);
  typedef void (*getparameterfct) (SEXP, int, int);
  typedef void (*finalsetparameterfct) (int);
  typedef void (*deleteparameterfct) (int);

  #define MAXNLIST 7
  
  //  DECLARE1(void, linkRFUoptions, utilsoption_type ** up)
  DECLARE1(void, getUtilsParam, utilsoption_type ** up)
  DECLARE1(void, getErrorString, errorstring_type errorstring)
  DECLARE1(void, setErrorLoc, errorloc_type errorloc)
  DECLARE1(void, relaxUnknownRFoption, bool relax)
  DECLARE10(void, attachRFoptions, const char ** prefixlist, int N, 
	   const char *** all, int * allN, setparameterfct set, 
	   finalsetparameterfct final, getparameterfct get,
	    deleteparameterfct del,
	   int pl_offset,
	   bool basicopt)
  DECLARE2(void, detachRFoptions, const char ** prefixlist, int N)
  DECLARE3(int *, ToIntI, SEXP X, bool * create, bool round)
  
  DECLARE2(bool, is_positive_definite, double * C, int dim)
  DECLARE2(double, detPosDef, double * M,  int size) // destroys M!
   DECLARE2(int, invertMatrix, double * M, int size)
  DECLARE3(double, detPosDefsp, double * M, int size, solve_options * sp)
 DECLARE8(int, XCinvXdet,double* M, int size, double *X, int X_cols,
	  double * XCinvX, double * det, bool log, solve_storage *PT)
  DECLARE10(int, XCinvYdet,double* M, int size, bool posdef,
	    double * X, double * Y, int cols,
	    double * XCinvY, double * det, bool log, solve_storage *PT)
   DECLARE2(int, chol, double * MPT, int size)
 DECLARE7(int, solvePosDef, double* M, int size, bool posdef, 
	   double * rhs, int rhs_cols, double * logdet, solve_storage * PT)
  DECLARE8(int, solvePosDefSp, double * M, int size, bool posdef,
	   double * rhs, int rhs_cols, double *logdet,
	   solve_storage * Pt, solve_options *sp)
  DECLARE4(int, sqrtPosDefFree, double * M, int size, solve_storage * pt,
	   solve_options * sp)
  
  #define warn(X) {RFWARNING(X);}

#endif

  

 /* 
!!!!! HIER NIE EIN SEXP OBJEKT ZURUECKGEBEN  !!!!  
  */
 
  /*

    See in R package RandomFields, /src/userinterfaces.cc 
          CALL#(...)
    at the beginning for how to make the functions available
    in a calling package

  */
#ifdef __cplusplus
}
#endif


#endif
