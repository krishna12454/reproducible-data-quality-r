/*
 Authors 
 Martin Schlather, schlather@math.uni-mannheim.de

 Copyright (C) 2021 -- 2021 Martin Schlather

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

#ifndef basic_rfutils_local_h
#define basic_rfutils_local_h 1

#define RFU_LOCAL 1  

#include "intrinsics.h"
#include "Basic_utils.h"

#define F77dgeqrf F77call(dgeqrf)
#define F77dsyevr F77call(dsyevr)
#define F77dgetrf F77call(dgetrf)
#define F77dgetrs F77call(dgetrs)
#define F77dgetri F77call(dgetri)
#define F77dgesv F77call(dgesv)
#define F77dpotrf F77call(dpotrf)
#define F77dtrmv F77call(dtrmv)


F77name(spamdnscsr)(int *nrow, int* ncol, double* dns, int* ndns, double* a, int* ja, int* ia, double* eps);//
#define F77spamdnscsr F77call(spamdnscsr)
F77name(cholstepwise)(int*, int*, double* , int*, int*, int*, int*, int*, int*, int*, int*, int*, int*, int*, double*  , int*, int*, int*, int*, int*);
#define F77cholstepwise F77call(cholstepwise)

F77name(calcja)(int*, int*, int*, int*, int*, int*, int*);
#define F77calcja F77call(calcja)

F77name(spamcsrdns)(int*,  double *, int *, int*, double*  ); // ok
#define F77spamcsrdns F77call(spamcsrdns)
F77name(backsolves)(int*, int*, int*, int*, int*, double*  , int*, int*, int*, int*, double*  , double*  );
#define F77backsolves F77call(backsolves)
F77name(amuxmat)(int*, int*, int*, double*  , double*  , double*  , int*, int*);
#define F77amuxmat F77call(amuxmat)


#endif
