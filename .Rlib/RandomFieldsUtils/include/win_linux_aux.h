


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


#ifndef WIN_LINUX_AUX_H
#define WIN_LINUX_AUX_H 1

uint32_t cpuid_info(int Blatt, int Register);//MINGWCPUID, WINCPUID, LINUXCPUID

#ifdef __cplusplus
extern "C" {
#endif
  void sleepMilli(int *milli);
  void sleepMicro(int *milli);
  void pid(int *i);
  void hostname(char **h, int *i);
  bool
    parallel();
#ifdef __cplusplus
}
#endif


#endif /* WIN_LINUX_AUX_H */


