

/*--------------------------------------------------------------------------------------*/
/*                  Multiple-Plot Displays: Simplified with Macros                      */
/*                                by Perry Watts                                        */
/*              Copyright(c) 2002 by SAS Institute Inc., Cary, NC, USA                  */
/*                       SAS Publications order # 58314                                 */
/*                             ISBN 1-59047-037-0                                       */
/*--------------------------------------------------------------------------------------*/
/*                                                                                      */
/* This material is provided "as is" by SAS Institute Inc.  There                       */
/* are no warranties, expressed or implied, as to merchantability or                    */
/* fitness for a particular purpose regarding the materials or code                     */
/* contained herein. The Institute is not responsible for errors                        */
/* in this material as it now exists or will exist, nor does the                        */
/* Institute provide technical support for it.                                          */
/*                                                                                      */
/*--------------------------------------------------------------------------------------*/
/*                                                                                      */
/* Questions or problem reports concerning this material may be                         */
/* addressed to the author:                                                             */
/*                                                                                      */
/* SAS Institute Inc.                                                                   */
/* Books by Users Press                                                                 */
/* Attn:  Perry Watts                                                                   */
/* SAS Campus Drive                                                                     */
/* Cary, NC   27513                                                                     */
/*                                                                                      */
/*                                                                                      */
/* If you prefer, you can send email to:  sasbbu@sas.com                                */
/* Use this for subject field:                                                          */
/* Comments for Perry Watts                                                             */
/*                                                                                      */
/*--------------------------------------------------------------------------------------*/
/* Date Last Updated:  6Mar02                                                           */ 
/*--------------------------------------------------------------------------------------*/

/*
SAS programs from "Multiple-Plot Displays: Simplified with Macros" are listed in the 
following order:
               GREPLAY Extension Macros
               Baseball Matrix
               Mouse Tumor Growth Study
               Survival Analysis
The extension macros are included into a calling program through the autocall facility,
and only the WINPRTC, CGM and HTML graphics devices are used in the programs. Input data
are read in with a CARDS statement.
*/

**GREPLAY Extension Macros;


/*  -----------------------------------------------------------------------
    Program  :  DelGCat.sas
    Purpose  :  Delete all entries from the graphics catalog specified
                as a parameter.
     ------------------------------------------------------------------- */
%macro DelGCat(CatName);
  %if %sysfunc(cexist(&CatName)) %then
    %do;
       proc greplay igout=&CatName nofs;
         delete _all_;
       run;
       quit;
    %end;
%mend DelGCat;
