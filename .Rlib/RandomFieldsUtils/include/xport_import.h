
#ifndef RandomFieldsUtilsxport_H
#define RandomFieldsUtilsxport_H 1


typedef
struct KEY_type KEY_type;
struct KEY_type {
  KEY_type *next;
  utilsoption_type global_utils;
  int pid,  visitingpid;
  bool ok, doshow;
  errorstring_type error_location;

  int *ToIntDummy;
  int ToIntN, ToRealN ;
  double *ToRealDummy;

  double loggamma1old, nu1old,
    loggamma2old, nu2old,
    loggamma_old,nuOld,
    gamma, nuAlt;
};
extern KEY_type *PIDKEY[PIDMODULUS];
KEY_type *KEYT();

typedef
struct option_type option_type;
utilsoption_type *WhichOptionList(bool local);

extern const char *R_TYPE_NAMES[LAST_R_TYPE_NAME + 1];

#endif
