#ifndef auto_rfutils_local_h
#define auto_rfutils_local_h 1



// Reihenfolge nie aendern!!
typedef enum la_modes {LA_INTERN, LA_R, LA_AUTO, LA_GPU,
		       LA_QUERY} la_modes; 
#define LA_LAST LA_QUERY
// Reihenfolge nie aendern!!
typedef enum pivot_modes {PIVOT_NONE,  PIVOT_DO, PIVOT_AUTO, PIVOT_IDX,
			  PIVOT_UNDEFINED} pivot_modes;
#define PIVOT_LAST PIVOT_UNDEFINED

#define PIVOTSPARSE_MMD 1 // for spam
#define PIVOTSPARSE_RCM 2 // for spam

typedef enum install_modes {Inone, Iinstall, Iask, Isse, Isse2, // 4
			    Isse3, Issse3, Iavx,  Iavx2, Iavx512f, // 8
			    Igpu} install_modes;
#define INSTALL_LAST Igpu


typedef enum InversionMethod { 
  Cholesky, // 0
  SVD,  // 1
  Eigen, // 2
  Sparse, // 3
  NoInversionMethod, // 4, last user available method
  QR, // 5
  LU, // 6 currently not propagated
  NoFurtherInversionMethod, // 7, local values
  GPUcholesky,		    // 8
  Rcholesky,                // 9
  direct_formula,           // 10
  Diagonal // 10, always last one!
} InversionMethod;

#define nr_InversionMethods ((int) Diagonal + 1)
#define nr_user_InversionMethods ((int) NoFurtherInversionMethod + 1)

#define LAST_R_TYPE_NAME 32

#endif
  
