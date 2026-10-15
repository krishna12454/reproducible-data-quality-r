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

#ifndef rfutils_calls_H
#define rfutils_calls_H 1

/* 
in xport_import.cc of calling packages set 
#ifdefine ERROR_RFU_CALLS 1
#include "xport_import.h"
...
// #define CALL(what) Ext_##what = (what##_type) R_GetCCallable(importfrom, #what)
#define CALL(what) Ext_##what = #what_err;

see RandomFields, for instance
#in clude <R_ext/Rdynload.h>


*/

#ifdef ERROR_RFU_CALLS		     
#define RFU_ERRCALL0(TYPE, FCTN)				\
  static TYPE FCTN##_err(){char msg[300]; SPRINTF(msg, "calling %.50s", #N); RFERROR(msg); }	
#define RFU_ERRCALL(TYPE, FCTN, ...)					\
  static TYPE FCTN##_err(__VA_ARGS__) { char msg[300]; SPRINTF(msg, "calling %.50s", #N); RFERROR(msg);} 
#else
#define RFU_ERRCALL0(TYPE, FCTN)
#define RFU_ERRCALL(TYPE, FCTN, ...)
#endif

#define DECLARE0(TYPE, FCTN)			\
  typedef TYPE (*FCTN##_type)();		\
  attribute_hidden TYPE RU_##FCTN();		\
  TYPE FCTN();					\
  RFU_ERRCALL0(TYPE, FCTN)

#define DECLARE1(TYPE, FCTN, A)			\
  typedef TYPE (*FCTN##_type)(A);		\
  attribute_hidden TYPE RU_##FCTN(A);		\
  TYPE FCTN(A);					\
  RFU_ERRCALL(TYPE, FCTN, A)

#define DECLARE2(TYPE, FCTN, A, B)		\
  typedef TYPE (*FCTN##_type)(A, B);		\
  attribute_hidden TYPE RU_##FCTN(A, B);	\
  TYPE FCTN(A, B);				\
  RFU_ERRCALL(TYPE, FCTN, A, B)
  
#define DECLARE3(TYPE, FCTN, A, B, C)		\
  typedef TYPE (*FCTN##_type)(A, B, C);		\
  attribute_hidden TYPE RU_##FCTN(A, B, C);	\
  TYPE FCTN(A, B, C);\
  RFU_ERRCALL(TYPE, FCTN, A, B, C)
  
#define DECLARE4(TYPE, FCTN, A, B, C, D)	\
  typedef TYPE (*FCTN##_type)(A, B, C, D);	\
  attribute_hidden TYPE RU_##FCTN(A, B, C, D);	\
  TYPE FCTN(A, B, C, D);			\
  RFU_ERRCALL(TYPE, FCTN, A, B, C, D)
  
#define DECLARE5(TYPE, FCTN, A, B, C, D, E)		\
  typedef TYPE (*FCTN##_type)(A, B, C, D, E);		\
  attribute_hidden TYPE RU_##FCTN(A, B, C, D, E);	\
  TYPE FCTN(A, B, C, D, E);				\
  RFU_ERRCALL(TYPE, FCTN, A, B, C, D, E)
  
#define DECLARE6(TYPE, FCTN, A, B, C, D, E, F)		\
  typedef TYPE (*FCTN##_type)(A, B, C, D, E, F);	\
  attribute_hidden TYPE RU_##FCTN(A, B, C, D, E, F);	\
  TYPE FCTN(A, B, C, D, E, F);				\
  RFU_ERRCALL(TYPE, FCTN, A, B, C, D, E, F)
  
#define DECLARE7(TYPE, FCTN, A, B, C, D, E, F, G)	\
  typedef TYPE (*FCTN##_type)(A, B, C, D, E, F, G);	\
  attribute_hidden TYPE RU_##FCTN(A, B, C, D, E, F, G); \
  TYPE FCTN(A, B, C, D, E, F, G);			\
  RFU_ERRCALL(TYPE, FCTN, A, B, C, D, E, F, G)
  
#define DECLARE8(TYPE, FCTN, A, B, C, D, E, F, G, H)	   \
  typedef TYPE (*FCTN##_type)(A, B, C, D, E, F, G, H);	   \
  attribute_hidden TYPE RU_##FCTN(A, B, C, D, E, F, G, H); \
  TYPE FCTN(A, B, C, D, E, F, G, H);			   \
  RFU_ERRCALL(TYPE, FCTN, A, B, C, D, E, F, G, H)

#define DECLARE9(TYPE, FCTN, A, B, C, D, E, F, G, H, I)	      \
  typedef TYPE (*FCTN##_type)(A, B, C, D, E, F, G, H, I);     \
  attribute_hidden TYPE RU_##FCTN(A, B, C, D, E, F, G, H, I); \
  TYPE FCTN(A, B, C, D, E, F, G, H, I);			      \
  RFU_ERRCALL(TYPE, FCTN, A, B, C, D, E, F, G, H, I)

#define DECLARE10(TYPE, FCTN, A, B, C, D, E, F, G, H, I, J)	 \
  typedef TYPE (*FCTN##_type)(A, B, C, D, E, F, G, H, I, J);	 \
  attribute_hidden TYPE RU_##FCTN(A, B, C, D, E, F, G, H, I, J); \
  TYPE FCTN(A, B, C, D, E, F, G, H, I, J);			 \
  RFU_ERRCALL(TYPE, FCTN, A, B, C, D, E, F, G, H, I, J)

#define DECLARE11(TYPE, FCTN, A, B, C, D, E, F, G, H, I, J, K)	    \
  typedef TYPE (*FCTN##_type)(A, B, C, D, E, F, G, H, I, J, K);	    \
  attribute_hidden TYPE RU_##FCTN(A, B, C, D, E, F, G, H, I, J, K); \
  TYPE FCTN(A, B, C, D, E, F, G, H, I, J, K);			    \
  RFU_ERRCALL(TYPE, FCTN, A, B, C, D, E, F, G, H, I, J, K)

#define DECLARE12(TYPE, FCTN, A, B, C, D, E, F, G, H, I, J, K, L)      \
  typedef TYPE (*FCTN##_type)(A, B, C, D, E, F, G, H, I, J, K, L);     \
  attribute_hidden TYPE RU_##FCTN(A, B, C, D, E, F, G, H, I, J, K, L); \
  TYPE FCTN(A, B, C, D, E, F, G, H, I, J, K, L);		       \
  RFU_ERRCALL(TYPE, FCTN, A, B, C, D, E, F, G, H, I, J, K, L)

#define DECLARE13(TYPE, FCTN, A, B, C, D, E, F, G, H, I, J, K, L, M)	\
  typedef TYPE (*FCTN##_type)(A, B, C, D, E, F, G, H, I, J, K, L, M);	\
  attribute_hidden TYPE RU_##FCTN(A, B, C, D, E, F, G, H, I, J, K, L, M); \
  TYPE FCTN(A, B, C, D, E, F, G, H, I, J, K, L, M);			\
  RFU_ERRCALL(TYPE, FCTN, A, B, C, D, E, F, G, H, I, J, K, L, M)

#define DECLARE14(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N) \
  typedef TYPE (*FCTN##_type)(A,B,C,D,E,F,G,H,I,J,K,L,M,N); \
  attribute_hidden TYPE RU_##FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N); \
  TYPE FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N);			\
  RFU_ERRCALL(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N)


#define DECLARE15(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N, O) \
  typedef TYPE (*FCTN##_type)(A,B,C,D,E,F,G,H,I,J,K,L,M,N, O); \
  attribute_hidden TYPE RU_##FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N, O); \
  TYPE FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N, O); \
  RFU_ERRCALL(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N, O)

  
#define DECLARE16(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P) \
  typedef TYPE (*FCTN##_type)(A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P); \
  attribute_hidden TYPE RU_##FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P); \
  TYPE FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P);		\
  RFU_ERRCALL(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P)


#define DECLARE17(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P, Q) \
  typedef TYPE (*FCTN##_type)(A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P, Q); \
  attribute_hidden TYPE RU_##FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P, Q); \
  TYPE FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P, Q); \
  RFU_ERRCALL(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P, Q)


#define DECLARE18(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P, Q, R) \
  typedef TYPE (*FCTN##_type)(A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P, Q, R); \
  attribute_hidden TYPE RU_##FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P, Q, R); \
  TYPE FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P, Q, R);	\
  RFU_ERRCALL(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P, Q, R)


#define DECLARE19(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P, Q, R, S) \
  typedef TYPE (*FCTN##_type)(A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P, Q, R, S); \
  attribute_hidden TYPE RU_##FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P, Q, R, S); \
  TYPE FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P, Q, R, S); \
  RFU_ERRCALL(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N, O, P, Q, R, S)


#define DECLARE20(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T) \
  typedef TYPE (*FCTN##_type)(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T); \
  attribute_hidden TYPE RU_##FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T); \
  TYPE FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T); \
  RFU_ERRCALL(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T)


#define DECLARE21(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U) \
  typedef TYPE (*FCTN##_type)(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U); \
  attribute_hidden TYPE RU_##FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U); \
  TYPE FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U);			\
  RFU_ERRCALL(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U)


#define DECLARE22(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V) \
	typedef TYPE (*FCTN##_type)(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V); \
	attribute_hidden TYPE RU_##FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V); \
	TYPE FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V); \
	RFU_ERRCALL(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V)

#define DECLARE23(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W) \
	typedef TYPE (*FCTN##_type)(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W); \
	attribute_hidden TYPE RU_##FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W); \
	TYPE FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W); \
	RFU_ERRCALL(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W)

#define DECLARE24(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W, X) \
	typedef TYPE (*FCTN##_type)(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W, X); \
	attribute_hidden TYPE RU_##FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W, X); \
	TYPE FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W, X); \
	RFU_ERRCALL(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W, X)

#define DECLARE25(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W, X, Y) \
	typedef TYPE (*FCTN##_type)(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W, X, Y); \
	attribute_hidden TYPE RU_##FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W, X, Y); \
	TYPE FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W, X, Y); \
	RFU_ERRCALL(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W, X, Y)

#define DECLARE26(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W, X, Y, Z) \
	typedef TYPE (*FCTN##_type)(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W, X, Y, Z); \
	attribute_hidden TYPE RU_##FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W, X, Y, Z); \
	TYPE FCTN(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W, X, Y, Z); \
	RFU_ERRCALL(TYPE, FCTN, A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V, W, X, Y, Z)



#endif
