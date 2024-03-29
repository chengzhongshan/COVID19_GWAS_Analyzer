/*-----------------------------------------*
  |  Macro to generate a format of the form |
  |    1 ="&val1"  2="&val2" ...            |
  |  for observation labels on the y axis.  |
  *-----------------------------------------*/
%macro makefmt(nval);
  %if &sysver < 6 & "&sysscp"="CMS"
      %then %do;
        x set cmstype ht;              /* For SAS 5.18 on CMS, must    */
        x erase _yname_ text *;        /* erase format so that dotplot */
        x set cmstype rt;              /* can be used more than once   */
      %end;                            /* in a single SAS session      */
  %local i ;
  proc format;
       value _yname_
    %do i=1 %to &nval ;
       &i = "&&val&i"
       %end;
       ;
%mend makefmt;

%macro dotplot(
       data=_LAST_,          /* input data set                         */
       xvar=,                /* horizontal variable (response)         */
       xorder=,              /* plotting range of response             */
       xref=,                /* reference lines for response variable  */
       yvar=,                /* vertical variable (observation label)  */
       ysortby=&xvar,        /* how to sort observations               */
       ylabel=,              /* label for y variable                   */
       group=,               /* vertical grouping variable             */
       gpfmt=,               /* format for printing group variable     */
                             /* value (include the . at the end)       */
       connect=DOT,          /* draw lines to ZERO, DOT, AXIS, or NONE */
       dline=2,              /* style of horizontal lines              */
       dcolor=BLACK,         /* color of horizontal lines              */
       errbar=,              /* variable giving length of error bar    */
                             /* for each observation                   */
       errbar_size=0.25, /*adjust the number to increase or reduce error bar size*/
       dot_symbol=dot,/*Other symbols, including square, diamond, triangle, or other sas accept symbols;
                                        /*customized text with single or double quotes such as '+' is also applicable*/
       dot_symbol_color=darkgreen,
       fig_width=600, /*Figure width in pixel*/
       fig_height=600,/*Figure height in pixel*/
       name=DOTPLOT);        /* Name for graphic catalog entry         */

%if &yvar= %str() %then %do;
   %put DOTPLOT: Must specify y variable;
   %goto ENDDOT;
   %end;
%let connect=%upcase(&connect);
%if &ylabel = %str() %then %let ylabel=%upcase(&yvar);
%global nobs vref;
 /*--------------------------------------------------*
  | Sort observations in the desired order on Y axis |
  *--------------------------------------------------*/
%if &group ^= %str() OR &ysortby ^= %str() %then %do;
proc sort data=&data;
   by &group &ysortby;
%end;

 /*-----------------------------------------------------*
  | Add Sort_Key variable and construct macro variables |
  *-----------------------------------------------------*/
data _dot_dat;
  set &data;
  %if &group = %str() %then %do;
     %let group= _GROUP_;
     _group_ = 1;
  %end;
run;

data _dot_dat;
  set _dot_dat end=eof;
  retain vref ; drop vref;
  length vref $60;
     by &group;
  sort_key + 1;
  call symput( 'val' || left(put( sort_key, 3. )), trim(&yvar) );
  output;     /* output here so sort_key is in sync */

  if _n_=1 then vref='';
  if last.&group & ^eof then do;
     sort_key+1;
     vref = trim(vref) || put(sort_key, 5.);
     call symput('val'|| left(put(sort_key, 3.)), '  ' );
     end;
  if eof then do;
     call symput('nobs', put(sort_key, 4.));
     call symput('vref', trim(vref));
     end;
run;

%if &nobs=0 %then %do;
   %put DOTPLOT: Data set &data has no observations;
   %goto ENDDOT;
   %end;
%makefmt(&nobs);

 /*---------------------------------------------------*
  | Annotate data set to draw horizontal dotted lines |
  *---------------------------------------------------*/
data _dots_;
   set _dot_dat;
      by &group;
   length function $ 8 text $ 20;
   text = ' ';
   %if &connect = ZERO
       %then %str(xsys = '2';) ;
       %else %str(xsys = '1';) ;
   ysys = '2';
   line = &dline;
   color = "&dcolor";
   y  = sort_key;
   x = 0;
   function ='MOVE'; output;

   function ='DRAW';
   %if &connect = DOT | &connect = ZERO
       %then %do;
          xsys = '2';
          x = &xvar; output;
       %end;
       %else %if &connect = AXIS
          %then %do;
          function='POINT'; 
          do x = 0 to 100 by 2;
             output;
             end;
          %end;

   %if &group ^= _GROUP_ %then %do;
      if first.&group then do;
         xsys = '1';
         x = 98; size=1.5;
         function = 'LABEL';
         color='BLACK';
         position = 'A';
         %if &gpfmt ^= %str()
            %then %str(text = put(&group, &gpfmt ) ;) ;
            %else %str(text = &group ;) ;
         output;
      end;
   %end;

%if &errbar ^= %str() %then %do;
data _err_;
   set _dot_dat;
   %annomac;
   %system(2,2); /* Use system 2 for the horiz. coordinate and 1 for vertical */
   %line(&xvar-&errbar,sort_key,&xvar+&errbar,sort_key,black,1,1);
   %line(&xvar-&errbar,sort_key-&errbar_size,&xvar-&errbar,sort_key+&errbar_size,black,1,1);
   %line(&xvar+&errbar,sort_key-&errbar_size,&xvar+&errbar,sort_key+&errbar_size,black,1,1);
   

data _dots_;
   set _dots_ _err_;
%end;
 /*-----------------------------------------------*
  | Draw the dot plot, plotting formatted Y vs. X |
  *-----------------------------------------------*/

*this will change the figure size and ticks label font size;
*Add htext=num to adjust figure label and tick font size;
goptions reset=all ftext='arial' 
         dev=gif xpixels=&fig_width ypixels=&fig_height gsfname=gout;

proc gplot data= _dot_dat ;
   plot sort_key * &xvar
        /vaxis=axis1 vminor=0
         haxis=axis2 frame
         name="&name"
     %if &vref ^= %str()
     %then    vref=&vref ;
     %if &xref ^= %str()
     %then    href=&xref lhref=21 chref=red ;
         annotate=_dots_;
   label   sort_key="&ylabel";
   format  sort_key _yname_.;
  *Change symbol for the mean in the plot;
  *such as dot circle square star, as well as 'A' '+' and others;
   symbol1 v=&dot_symbol h=1.4 c=&dot_symbol_color;
   axis1   order=(1 to &nobs by 1)   label=(a=90 f=Arial)
           major=none value=(j=r f=Arial);
   axis2   %if %length(&xorder)>0 %then order=(&xorder) ;
           label=(f=Arial) offset=(1);
   run;
%enddot:
%mend dotplot;

/*	Demo:
goptions reset=all;
data baseball;
   input name $1-14
         league $15 team $16-18 position $19-20
         atbat  3. hits  3. homer  3. runs  3. rbi  3. walks  3. years 3.
         atbatc 5. hitsc 4. homerc 4. runsc 4. rbic 4. walksc 4.
         putouts 4. assists 3. errors 3. salary 4.;
   batavg = round(1000 * (hits / atbat));
   batavgc= round(1000 * (hitsc/ atbatc));
   label
      name    = "Hitter's name"
      atbat   = 'Times at Bat'
      hits    = 'Hits'
      homer   = 'Home Runs'
      runs    = 'Runs'
      rbi     = 'Runs Batted In'
      walks   = 'Walks'
      years   = 'Years in the Major Leagues'
      atbatc  = 'Career Times at Bat'
      hitsc   = 'Career Hits'
      homerc  = 'Career Home Runs'
      runsc   = 'Career Runs Scored'
      rbic    = 'Career Runs Batted In'
      position= 'Position(s)'
      putouts = 'Put Outs'
      assists = 'Assists'
      errors  = 'Errors'
      salary  = 'Salary (in 1000$)'
      batavg  = 'Batting Average'
      batavgc = 'Career Batting Average';
 cards;
Andy Allanson ACLEC 293 66  1 30 29 14  1  293  66   1  30  29  14 446 33 20   .
Alan Ashby    NHOUC 315 81  7 24 38 39 14 3449 835  69 321 414 375 632 43 10 475
Alvin Davis   ASEA1B479130 18 66 72 76  3 1624 457  63 224 266 263 880 82 14 480
Andre Dawson  NMONRF496141 20 65 78 37 11 56281575 225 828 838 354 200 11  3 500
A Galarraga   NMON1B321 87 10 39 42 30  2  396 101  12  48  46  33 805 40  4  92
A Griffin     AOAKSS594169  4 74 51 35 11 44081133  19 501 336 194 282421 25 750
Al Newman     NMON2B185 37  1 23  8 21  2  214  42   1  30   9  24  76127  7  70
A Salazar     AKC SS298 73  0 24 24  7  3  509 108   0  41  37  12 121283  9 100
Andres Thomas NATLSS323 81  6 26 32  8  2  341  86   6  32  34   8 143290 19  75
A Thornton    ACLEDH401 92 17 49 66 65 13 52061332 253 784 890 866   0  0  01100
Alan Trammell ADETSS574159 21107 75 59 10 46311300  90 702 504 488 238445 22 517
Alex Trevino  NLA C 202 53  4 31 26 27  9 1876 467  15 192 186 161 304 45 11 513
A Van.Slyke   NSTLRF418113 13 48 61 47  4 1512 392  41 205 204 203 211 11  7 550
Alan Wiggins  ABAL2B239 60  0 30 11 22  6 1941 510   4 309 103 207 121151  6 700
Bill Almon    NPITUT196 43  7 29 27 30 13 3231 825  36 376 290 238  80 45  8 240
Billy Beane   AMINOF183 39  3 20 15 11  3  201  42   3  20  16  11 118  0  0   .
Buddy Bell    NCIN3B568158 20 89 75 73 15 80682273 1771045 993 732 105290 10 775
B Biancalana  AKC SS190 46  2 24  8 15  5  479 102   5  65  23  39 102177 16 175
Bruce Bochte  AOAK1B407104  6 57 43 65 12 52331478 100 643 658 653 912 88  9   .
Bruce Bochy   NSD C 127 32  8 16 22 14  8  727 180  24  67  82  56 202 22  2 135
Barry Bonds   NPITCF413 92 16 72 48 65  1  413  92  16  72  48  65 280  9  5 100
Bobby Bonilla ACHAO1426109  3 55 43 62  1  426 109   3  55  43  62 361 22  2 115
Bob Boone     ACALC  22 10  1  4  2  1  6   84  26   2   9   9   3 812 84 11   .
Bob Brenly    NSF C 472116 16 60 62 74  6 1924 489  67 242 251 240 518 55  3 600
Bill Buckner  ABOS1B629168 18 73102 40 18 84242464 16410081072 4021067157 14 777
Brett Butler  ACLECF587163  4 92 51 70  6 2695 747  17 442 198 317 434  9  3 765
Bob Dernier   NCHNCF324 73  4 32 18 22  7 1931 491  13 291 108 180 222  3  3 708
Bo Diaz       NCINC 474129 10 50 56 40 10 2331 604  61 246 327 166 732 83 13 750
Bill Doran    NHOU2B550152  6 92 37 81  5 2308 633  32 349 182 308 262329 16 625
Brian Downing ACALLF513137 20 90 95 90 14 52011382 166 763 734 784 267  5  3 900
Bobby Grich   ACAL2B313 84  9 42 30 39 17 68901833 2241033 8641087 127221  7   .
Billy Hatcher NHOUCF419108  6 55 36 22  3  591 149   8  80  46  31 226  7  4 110
Bob Horner    NATL1B517141 27 70 87 52  9 3571 994 215 545 652 3371378102  8   .
Brook Jacoby  ACLE3B583168 17 83 80 56  5 1646 452  44 219 208 136 109292 25 613
Bob Kearney   ASEAC 204 49  6 23 25 12  7 1309 308  27 126 132  66 419 46  5 300
Bill Madlock  NLA 3B379106 10 38 60 30 14 62071906 146 859 803 571  72170 24 850
Bobby Meacham ANYASS161 36  0 19 10 17  4 1053 244   3 156  86 107  70149 12   .
Bob Melvin    NSF C 268 60  5 24 25 15  2  350  78   5  34  29  18 442 59  6  90
Ben Oglivie   AMILDH346 98  5 31 53 30 16 59131615 235 784 901 560   0  0  0   .
Bip Roberts   NSD 2B241 61  1 34 12 14  1  241  61   1  34  12  14 166172 10   .
B Robidoux    AMIL1B181 41  1 15 21 33  2  232  50   4  20  29  45 326 29  5  68
Bill Russell  NLA UT216 54  0 21 18 15 18 73181926  46 796 627 483 103 84  5   .
Billy Sample  NATLOF200 57  6 23 14 14  9 2516 684  46 371 230 195  69  1  1   .
B Schroeder   AMILUT217 46  7 32 19  9  4  694 160  32  86  76  32 307 25  1 180
Butch Wynegar ANYAC 194 40  7 19 29 30 11 41831069  64 486 493 608 325 22  2   .
Chris Bando   ACLEC 254 68  2 28 26 22  6  999 236  21 108 117 118 359 30  4 305
Chris Brown   NSF 3B416132  7 57 49 33  3  932 273  24 113 121  80  73177 18 215
C Castillo    ACLEOD205 57  8 34 32  9  5  756 192  32 117 107  51  58  4  4 248
Cecil Cooper  AMIL1B542140 12 46 75 41 16 70992130 235 9871089 431 697 61  9   .
Chili Davis   NSF RF526146 13 71 70 84  6 2648 715  77 352 342 289 303  9  9 815
Carlton Fisk  ACHAC 457101 14 42 63 22 17 65211767 2811003 977 619 389 39  4 875
Curt Ford     NSTLOF214 53  2 30 29 23  2  226  59   2  32  32  27 109  7  3  70
Cliff Johnson ATORDH 19  7  0  1  2  1  4   41  13   1   3   4   4   0  0  0   .
C Lansford    AOAK3B591168 19 80 72 39  9 44781307 113 634 563 319  67147  41200
Chet Lemon    ADETCF403101 12 45 53 39 12 51501429 166 747 666 526 316  6  5 675
C Maldonado   NSF OF405102 18 49 85 20  6  950 231  29  99 138  64 161 10  3 415
C Martinez    NSD O1244 58  9 28 25 35  4 1335 333  49 164 179 194 142 14  2 340
Charlie Moore AMILC 235 61  3 24 39 21 14 39261029  35 441 401 333 425 43  4   .
C Reynolds    NHOUSS313 78  6 32 41 12 12 3742 968  35 409 321 170 106206  7 417
Cal Ripken    ABALSS627177 25 98 81 70  6 3210 927 133 529 472 313 240482 131350
Cory Snyder   ACLEOS416113 24 58 69 16  1  416 113  24  58  69  16 203 70 10  90
Chris Speier  NCHN3S155 44  6 21 23 15 16 66311634  98 698 661 777  53 88  3 275
C Wilkerson   ATEX2S236 56  0 27 15 11  4 1115 270   1 116  64  57 125199 13 230
Dave Anderson NLA 3S216 53  1 31 15 22  4  926 210   9 118  69 114  73152 11 225
Doug Baker    AOAKOF 24  3  0  1  0  2  3  159  28   0  20  12   9  80  4  0   .
Don Baylor    ABOSDH585139 31 93 94 62 17 75461982 31511411179 727   0  0  0 950
D Bilardello  NMONC 191 37  4 12 17 14  4  773 163  16  61  74  52 391 38  8   .
Daryl Boston  ACHACF199 53  5 29 22 21  3  514 120   8  57  40  39 152  3  5  75
Darnell Coles ADET3B521142 20 67 86 45  4  815 205  22  99 103  78 107242 23 105
Dave Collins  ADETLF419113  1 44 27 44 12 44841231  32 612 344 422 211  2  1   .
D Concepcion  NCINUT311 81  3 42 30 26 17 82472198 100 950 909 690 153223 10 320
D Daulton     NPHIC 138 31  8 18 21 38  3  244  53  12  33  32  55 244 21  4   .
Doug DeCinces ACAL3B512131 26 69 96 52 14 53471397 221 712 815 548 119216 12 850
Darrell Evans ADET1B507122 29 78 85 91 18 77611947 347117511521380 808108  2 535
Dwight Evans  ABOSRF529137 26 86 97 97 15 66611785 2911082 949 989 280 10  5 933
Damaso Garcia ATOR2B424119  6 57 46 13  9 36511046  32 461 301 112 224286  8 850
Dan Gladden   NSF CF351 97  4 55 29 39  4 1258 353  16 196 110 117 226  7  3 210
Danny Heep    NNYNOF195 55  5 24 33 30  8 1313 338  25 144 149 153  83  2  1   .
D Henderson   ASEAOF388103 15 59 47 39  6 2174 555  80 285 274 186 182  9  4 325
Donnie Hill   AOAK23339 96  4 37 29 23  4 1064 290  11 123 108  55 104213  9 275
Dave Kingman  AOAKDH561118 35 70 94 33 16 66771575 442 9011210 608 463 32  8   .
Davey Lopes   NCHN3O255 70  7 49 35 43 15 63111661 1541019 608 820  51 54  8 450
Don Mattingly ANYA1B677238 31117113 53  5 2223 737  93 349 401 1711377100  61975
Darryl Motley AKC RF227 46  7 23 20 12  5 1325 324  44 156 158  67  92  2  2   .
Dale Murphy   NATLCF614163 29 89 83 75 11 50171388 266 813 822 617 303  6  61900
Dwayne Murphy AOAKCF329 83  9 50 39 56  9 3828 948 145 575 528 635 276  6  2 600
Dave Parker   NCINRF637174 31 89116 56 14 67272024 247 9781093 495 278  9  91042
Dan Pasqua    ANYALF280 82 16 44 45 47  2  428 113  25  61  70  63 148  4  2 110
D Porter      ATEXCD155 41 12 21 29 22 16 54091338 181 746 805 875 165  9  1 260
D Schofield   ACALSS458114 13 67 57 48  4 1350 298  28 160 123 122 246389 18 475
Don Slaught   ATEXC 314 83 13 39 46 16  5 1457 405  28 156 159  76 533 40  4 432
D Strawberry  NNYNRF475123 27 76 93 72  4 1810 471 108 292 343 267 226 10  61220
Dale Sveum    AMIL3B317 78  7 35 35 32  1  317  78   7  35  35  32  45122 26  70
D Tartabull   ASEARF511138 25 76 96 61  3  592 164  28  87 110  71 157  7  8 145
Dickie Thon   NHOUSS278 69  3 24 21 29  8 2079 565  32 258 192 162 142210 10   .
Denny Walling NHOU3B382119 13 54 58 36 12 2133 594  41 287 294 227  59156  9 595
Dave Winfield ANYARF565148 24 90104 77 14 72872083 30511351234 791 292  9  51861
Enos Cabell   NLA 1B277 71  2 27 29 14 15 59521647  60 753 596 259 360 32  5   .
Eric Davis    NCINLF415115 27 97 71 68  3  711 184  45 156 119  99 274  2  7 300
Eddie Milner  NCINCF424110 15 70 47 36  7 2130 544  38 335 174 258 292  6  3 490
Eddie Murray  ABAL1B495151 17 61 84 78 10 56241679 275 8841015 7091045 88 132460
Ernest Riles  AMILSS524132  9 69 47 54  2  972 260  14 123  92  90 212327 20   .
Ed Romero     ABOSSS233 49  2 41 23 18  8 1350 336   7 166 122 106 102132 10 375
Ernie Whitt   ATORC 395106 16 48 56 35 10 2303 571  86 266 323 248 709 41  7   .
Fred Lynn     ABALCF397114 23 67 67 53 13 55891632 241 906 926 716 244  2  4   .
Floyd Rayford ABAL3B210 37  8 15 19 15  6  994 244  36 107 114  53  40115 15   .
F Stubbs      NLA LF420 95 23 55 58 37  3  646 139  31  77  77  61 206 10  7   .
Frank White   AKC 2B566154 22 76 84 43 14 61001583 131 743 693 300 316439 10 750
George Bell   ATORLF641198 31101108 41  5 2129 610  92 297 319 117 269 17 101175
Glenn Braggs  AMILLF215 51  4 19 18 11  1  215  51   4  19  18  11 116  5 12  70
George Brett  AKC 3B441128 16 70 73 80 14 66752095 20910721050 695  97218 161500
Greg Brock    NLA 1B325 76 16 33 52 37  5 1506 351  71 195 219 214 726 87  3 385
Gary Carter   NNYNC 490125 24 81105 62 13 60631646 271 847 999 680 869 62  81926
Glenn Davis   NHOU1B574152 31 91101 64  3  985 260  53 148 173  951253111 11 215
George Foster NNYNLF284 64 14 30 42 24 18 70231925 348 9861239 666  96  4  4   .
Gary Gaetti   AMIN3B596171 34 91108 52  6 2862 728 107 361 401 224 118334 21 900
Greg Gagne    AMINSS472118 12 63 54 30  4  793 187  14 102  80  50 228377 26 155
G Hendrick    ACALOF283 77 14 45 47 26 16 68401910 259 9151067 546 144  6  5 700
Glenn Hubbard NATL2B408 94  4 42 36 66  9 3573 866  59 429 365 410 282487 19 535
Garth Iorg    ATOR32327 85  3 30 44 20  8 2140 568  16 216 208  93  91185 12 363
Gary Matthews NCHNLF370 96 21 49 46 60 15 69861972 2311070 955 921 137  5  9 733
Graig Nettles NSD 3B354 77 16 36 55 41 20 87162172 384117212671057  83174 16 200
Gary Pettis   ACALCF539139  5 93 58 69  5 1469 369  12 247 126 198 462  9  7 400
Gary Redus    NPHILF340 84 11 62 33 47  5 1516 376  42 284 141 219 185  8  4 400
G Templeton   NSD SS510126  2 42 44 35 11 55621578  44 703 519 256 207358 20 738
Gorman Thomas ASEADH315 59 16 45 36 58 13 46771051 268 681 782 697   0  0  0   .
Greg Walker   ACHA1B282 78 13 37 51 29  5 1649 453  73 211 280 138 670 57  5 500
Gary Ward     ATEXLF380120  5 54 51 31  8 3118 900  92 444 419 240 237  8  1 600
Glenn Wilson  NPHIRF584158 15 70 84 42  5 2358 636  58 265 316 134 331 20  4 663
Harold Baines ACHARF570169 21 72 88 38  7 37541077 140 492 589 263 295 15  5 950
Hubie Brooks  NMONSS306104 14 50 58 25  7 2954 822  55 313 377 187 116222 15 750
H Johnson     NNYN3S220 54 10 30 39 31  5 1185 299  40 145 154 128  50136 20 298
Hal McRae     AKC DH278 70  7 22 37 18 18 71862081 190 9351088 643   0  0  0 325
H Reynolds    ASEA2B445 99  1 46 24 29  4  618 129   1  72  31  48 278415 16  88
Harry Spilman NSF 1B143 39  5 18 30 15  9  639 151  16  80  97  61 138 15  1 175
H Winningham  NMONOF185 40  4 23 11 18  3  524 125   7  58  37  47  97  2  2  90
J Barfield    ATORRF589170 40107108 69  6 2325 634 128 371 376 238 368 20  31238
Juan Beniquez ABALUT343103  6 48 36 40 15 43381193  70 581 421 325 211 56 13 430
Juan Bonilla  ABAL2B284 69  1 33 18 25  5 1407 361   6 139  98 111 122140  5   .
J Cangelosi   ACHALF438103  2 65 32 71  2  440 103   2  67  32  71 276  7  9 100
Jose Canseco  AOAKLF600144 33 85117 65  2  696 173  38 101 130  69 319  4 14 165
Joe Carter    ACLERF663200 29108121 32  4 1447 404  57 210 222  68 241  8  6 250
Jack Clark    NSTL1B232 55  9 34 23 45 12 44051213 194 702 705 625 623 35  31300
Jose Cruz     NHOULF479133 10 48 72 55 17 74722147 153 9801032 854 237  5  4 773
Julio Cruz    ACHA2B209 45  0 38 19 42 10 3859 916  23 557 279 478 132205  5   .
Jody Davis    NCHNC 528132 21 61 74 41  6 2641 671  97 273 383 226 885105  81008
Jim Dwyer     ABALDO160 39  8 18 31 22 14 2128 543  56 304 268 298  33  3  0 275
Julio Franco  ACLESS599183 10 80 74 32  5 2482 715  27 330 326 158 231374 18 775
Jim Gantner   AMIL2B497136  7 58 38 26 11 38711066  40 450 367 241 304347 10 850
Johnny Grubb  ADETDH210 70 13 32 51 28 15 40401130  97 544 462 551   0  0  0 365
J Hairston    ACHAUT225 61  5 32 26 26 11 1568 408  25 202 185 257 132  9  0   .
Jack Howell   ACAL3B151 41  4 26 21 19  2  288  68   9  45  39  35  28 56  2  95
John Kruk     NSD LF278 86  4 33 38 45  1  278  86   4  33  38  45 102  4  2 110
J Leonard     NSF LF341 95  6 48 42 20 10 2964 808  81 379 428 221 158  4  5 100
Jim Morrison  NPIT3B537147 23 58 88 47 10 2744 730  97 302 351 174  92257 20 278
John Moses    ASEACF399102  3 56 34 34  5  670 167   4  89  48  54 211  9  3  80
J Mumphrey    NCHNOF309 94  5 37 32 26 13 46181330  57 616 522 436 161  3  3 600
Joe Orsulak   NPITRF401100  2 60 19 28  4  876 238   2 126  44  55 193 11  4   .
Jorge Orta    AKC DH336 93  9 35 46 23 15 57791610 128 730 741 497   0  0  0   .
Jim Presley   ASEA3B616163 27 83107 32  3 1437 377  65 181 227  82 110308 15 200
Jamie Quirk   AKC CS219 47  8 24 26 17 12 1188 286  23 100 125  63 260 58  4   .
Johnny Ray    NPIT2B579174  7 67 78 58  6 3053 880  32 366 337 218 280479  5 657
Jeff Reed     AMINC 165 39  2 13  9 16  3  196  44   2  18  10  18 332 19  2  75
Jim Rice      ABOSLF618200 20 98110 62 13 71272163 35111041289 564 330 16  82413
Jerry Royster NSD UT257 66  5 31 26 32 14 3910 979  33 518 324 382  87166 14 250
John Russell  NPHIC 315 76 13 35 60 25  3  630 151  24  68  94  55 498 39 13 155
Juan Samuel   NPHI2B591157 16 90 78 26  4 2020 541  52 310 226  91 290440 25 640
John Shelby   ABALOF404 92 11 54 49 18  6 1354 325  30 188 135  63 222  5  5 300
Joel Skinner  ACHAC 315 73  5 23 37 16  4  450 108   6  38  46  28 227 15  3 110
Jeff Stone    NPHIOF249 69  6 32 19 20  4  702 209  10  97  48  44 103  8  2   .
Jim Sundberg  AKC C 429 91 12 41 42 57 13 55901397  83 578 579 644 686 46  4 825
Jim Traber    ABALUT212 54 13 28 44 18  2  233  59  13  31  46  20 243 23  5   .
Jose Uribe    NSF SS453101  3 46 43 61  3  948 218   6  96  72  91 249444 16 195
Jerry Willard AOAKC 161 43  4 17 26 22  3  707 179  21  77  99  76 300 12  2   .
J Youngblood  NSF OF184 47  5 20 28 18 11 3327 890  74 419 382 304  49  2  0 450
Kevin Bass    NHOURF591184 20 83 79 38  5 1689 462  40 219 195  82 303 12  5 630
Kal Daniels   NCINOF181 58  6 34 23 22  1  181  58   6  34  23  22  88  0  3  87
Kirk Gibson   ADETRF441118 28 84 86 68  8 2723 750 126 433 420 309 190  2  21300
Ken Griffey   ANYAOF490150 21 69 58 35 14 61261839 121 983 707 600  96  5  31000
K Hernandez   NNYN1B551171 13 94 83 94 13 60901840 128 969 900 9171199149  51800
Kent Hrbek    AMIN1B550147 29 85 91 71  6 2816 815 117 405 474 3191218104 101310
Ken Landreaux NLA OF283 74  4 34 29 22 10 39191062  85 505 456 283 145  5  7 738
K McReynolds  NSD CF560161 26 89 96 66  4 1789 470  65 233 260 155 332  9  8 625
K Mitchell    NNYNOS328 91 12 51 43 33  2  342  94  12  51  44  33 145 59  8 125
K Moreland    NCHNRF586159 12 72 79 53  9 3082 880  83 363 477 295 181 13  41043
Ken Oberkfell NATL3B503136  5 62 48 83 10 3423 970  20 408 303 414  65258  8 725
Ken Phelps    ASEADH344 85 24 69 64 88  7  911 214  64 150 156 187   0  0  0 300
Kirby Puckett AMINCF680223 31119 96 34  3 1928 587  35 262 201  91 429  8  6 365
K Stillwell   NCINSS279 64  0 31 26 30  1  279  64   0  31  26  30 107205 16  75
Leon Durham   NCHN1B484127 20 66 65 67  7 3006 844 116 436 458 3771231 80  71183
Len Dykstra   NNYNCF431127  8 77 45 58  2  667 187   9 117  64  88 283  8  3 203
Larry Herndon ADETOF283 70  8 33 37 27 12 44791222  94 557 483 307 156  2  2 225
Lee Lacy      ABALRF491141 11 77 47 37 15 42911240  84 615 430 340 239  8  2 525
Len Matuszek  NLA O1199 52  9 26 28 21  6  805 191  30 113 119  87 235 22  5 265
Lloyd Moseby  ATORCF589149 21 89 86 64  7 3558 928 102 513 471 351 371  6  6 788
Lance Parrish ADETC 327 84 22 53 62 38 10 42731123 212 577 700 334 483 48  6 800
Larry Parrish ATEXDH464128 28 67 94 52 13 58291552 210 740 840 452   0  0  0 588
Luis Rivera   NMONSS166 34  0 20 13 17  1  166  34   0  20  13  17  64119  9   .
Larry Sheets  ABALDH338 92 18 42 60 21  3  682 185  36  88 112  50   0  0  0 145
Lonnie Smith  AKC LF508146  8 80 44 46  9 3148 915  41 571 289 326 245  5  9   .
Lou Whitaker  ADET2B584157 20 95 73 63 10 47041320  93 724 522 576 276421 11 420
Mike Aldrete  NSF 1O216 54  2 27 25 33  1  216  54   2  27  25  33 317 36  1  75
Marty Barrett ABOS2B625179  4 94 60 65  5 1696 476  12 216 163 166 303450 14 575
Mike Brown    NPITOF243 53  4 18 26 27  4  853 228  23 101 110  76 107  3  3   .
Mike Davis    AOAKRF489131 19 77 55 34  7 2051 549  62 300 263 153 310  9  9 780
Mike Diaz     NPITO1209 56 12 22 36 19  2  216  58  12  24  37  19 201  6  3  90
M Duncan      NLA SS407 93  8 47 30 30  2  969 230  14 121  69  68 172317 25 150
Mike Easler   ANYADH490148 14 64 78 49 13 34001000 113 445 491 301   0  0  0 700
M Fitzgerald  NMONC 209 59  6 20 37 27  4  884 209  14  66 106  92 415 35  3   .
Mel Hall      ACLELF442131 18 68 77 33  6 1416 398  47 210 203 136 233  7  7 550
M Hatcher     AMINUT317 88  3 40 32 19  8 2543 715  28 269 270 118 220 16  4   .
Mike Heath    NSTLC 288 65  8 30 36 27  9 2815 698  55 315 325 189 259 30 10 650
Mike Kingery  AKC OF209 54  3 25 14 12  1  209  54   3  25  14  12 102  6  3  68
M LaValliere  NSTLC 303 71  3 18 30 36  3  344  76   3  20  36  45 468 47  6 100
Mike Marshall NLA RF330 77 19 47 53 27  6 1928 516  90 247 288 161 149  8  6 670
M Pagliarulo  ANYA3B504120 28 71 71 54  3 1085 259  54 150 167 114 103283 19 175
Mark Salas    AMINC 258 60  8 28 33 18  3  638 170  17  80  75  36 358 32  8 137
Mike Schmidt  NPHI3B 20  1  0  0  0  0  2   41   9   2   6   7   4  78220  62127
Mike Scioscia NLA C 374 94  5 36 26 62  7 1968 519  26 181 199 288 756 64 15 875
M Tettleton   AOAKC 211 43 10 26 35 39  3  498 116  14  59  55  78 463 32  8 120
Milt Thompson NPHICF299 75  6 38 23 26  3  580 160   8  71  33  44 212  1  2 140
Mitch Webster NMONCF576167  8 89 49 57  4  822 232  19 132  83  79 325 12  8 210
Mookie Wilson NNYNOF381110  9 61 45 32  7 3015 834  40 451 249 168 228  7  5 800
Marvell Wynne NSD OF288 76  7 34 37 15  4 1644 408  16 198 120 113 203  3  3 240
Mike Young    ABALLF369 93  9 43 42 49  5 1258 323  54 181 177 157 149  1  6 350
Nick Esasky   NCIN1B330 76 12 35 41 47  4 1367 326  55 167 198 167 512 30  5   .
Ozzie Guillen ACHASS547137  2 58 47 12  2 1038 271   3 129  80  24 261459 22 175
O McDowell    ATEXCF572152 18105 49 65  2  978 249  36 168  91 101 325 13  3 200
Omar Moreno   NATLRF359 84  4 46 27 21 12 49921257  37 699 386 387 151  8  5   .
Ozzie Smith   NSTLSS514144  0 67 54 79  9 47391169  13 583 374 528 229453 151940
Ozzie Virgil  NATLC 359 80 15 45 48 63  7 1493 359  61 176 202 175 682 93 13 700
Phil Bradley  ASEALF526163 12 88 50 77  4 1556 470  38 245 167 174 250 11  1 750
Phil Garner   NHOU3B313 83  9 43 41 30 14 58851543 104 751 714 535  58141 23 450
P Incaviglia  ATEXRF540135 30 82 88 55  1  540 135  30  82  88  55 157  6 14 172
Paul Molitor  AMIL3B437123  9 62 55 40  9 41391203  79 676 390 364  82170 151260
Pete O'Brien  ATEX1B551160 23 86 90 87  5 2235 602  75 278 328 2731224115 11   .
Pete Rose     NCIN1B237 52  0 15 25 30 24140534256 160216513141566 523 43  6 750
Pat Sheridan  ADETOF236 56  6 41 19 21  5 1257 329  24 166 125 105 172  1  4 190
Pat Tabler    ACLE1B473154  6 61 48 29  6 1966 566  29 250 252 178 846 84  9 580
R Belliard    NPITSS309 72  0 33 31 26  5  354  82   0  41  32  26 117269 12 130
Rick Burleson ACALUT271 77  5 35 29 33 12 49331358  48 630 435 403  62 90  3 450
Randy Bush    AMINLF357 96  7 50 45 39  5 1394 344  43 178 192 136 167  2  4 300
Rick Cerone   AMILC 216 56  4 22 18 15 12 2796 665  43 266 304 198 391 44  4 250
Ron Cey       NCHN3B256 70 13 42 36 44 16 70581845 312 9651128 990  41118  81050
Rob Deer      AMILRF466108 33 75 86 72  3  652 142  44 102 109 102 286  8  8 215
Rick Dempsey  ABALC 327 68 13 42 29 45 18 3949 939  78 438 380 466 659 53  7 400
Rich Gedman   ABOSC 462119 16 49 65 37  7 2131 583  69 244 288 150 866 65  6   .
Ron Hassey    ANYAC 341110  9 45 49 46  9 2331 658  50 249 322 274 251  9  4 560
R Henderson   ANYACF608160 28130 74 89  8 40711182 103 862 417 708 426  4  61670
R Jackson     ACALDH419101 18 65 58 92 20 95282510 548150916591342   0  0  0 488
Ricky Jones   ACALRF 33  6  0  2  4  7  1   33   6   0   2   4   7 205  5  4   .
Ron Kittle    ACHADH376 82 21 42 60 35  5 1770 408 115 238 299 157   0  0  0 425
Ray Knight    NNYN3B486145 11 51 76 40 11 39671102  67 410 497 284  88204 16 500
Randy Kutcher NSF OF186 44  7 28 16 11  1  186  44   7  28  16  11  99  3  1   .
Rudy Law      AKC OF307 80  1 42 36 29  7 2421 656  18 379 198 184 145  2  2   .
Rick Leach    ATORDO246 76  5 35 39 13  6  912 234  12 102  96  80  44  0  1 250
Rick Manning  AMILOF205 52  8 31 27 17 12 51341323  56 643 445 459 155  3  2 400
R Mulliniks   ATOR3B348 90 11 50 45 43 10 2288 614  43 295 273 269  60176  6 450
Ron Oester    NCIN2B523135  8 52 44 52  9 3368 895  39 377 284 296 367475 19 750
Rey Quinones  ABOSSS312 68  2 32 22 24  1  312  68   2  32  22  24  86150 15  70
R Ramirez     NATLS3496119  8 57 33 21  7 3358 882  36 365 280 165 155371 29 875
Ronn Reynolds NPITLF126 27  3  8 10  5  4  239  49   3  16  13  14 190  2  9 190
Ron Roenicke  NPHIOF275 68  5 42 42 61  6  961 238  16 128 104 172 181  3  2 191
Ryne Sandberg NCHN2B627178 14 68 76 46  6 3146 902  74 494 345 242 309492  5 740
R Santana     NNYNSS394 86  1 38 28 36  4 1089 267   3  94  71  76 203369 16 250
Rick Schu     NPHI3B208 57  8 32 25 18  3  653 170  17  98  54  62  42 94 13 140
Ruben Sierra  ATEXOF382101 16 50 55 22  1  382 101  16  50  55  22 200  7  6  98
Roy Smalley   AMINDH459113 20 59 57 68 12 53481369 155 713 660 735   0  0  0 740
R Thompson    NSF 2B549149  7 73 47 42  1  549 149   7  73  47  42 255450 17 140
Rob Wilfong   ACAL2B288 63  3 25 33 16 10 2682 667  38 315 259 204 135257  7 342
R Williams    NLA CF303 84  4 35 32 23  2  312  87   4  39  32  23 179  5  3   .
Robin Yount   AMILCF522163  9 82 46 62 13 70372019 1531043 827 535 352  9  11000
Steve Balboni AKC 1B512117 29 54 88 43  6 1750 412 100 204 276 1551236 98 18 100
Scott Bradley ASEAC 220 66  5 20 28 13  3  290  80   5  27  31  15 281 21  3  90
Sid Bream     NPIT1B522140 16 73 77 60  4  730 185  22  93 106  861320166 17 200
S Buechele    ATEX3B461112 18 54 54 35  2  680 160  24  76  75  49 111226 11 135
S Dunston     NCHNSS581145 17 66 68 21  2  831 210  21 106  86  40 320465 32 155
S Fletcher    ATEXSS530159  3 82 50 47  6 1619 426  11 218 149 163 196354 15 475
Steve Garvey  NSD 1B557142 21 58 81 23 18 87592583 27111381299 4781160 53  71450
Steve Jeltz   NPHISS439 96  0 44 36 65  4  711 148   1  68  56  99 229406 22 150
S Lombardozzi AMIN2B453103  8 53 33 52  2  507 123   8  63  39  58 289407  6 105
Spike Owen    ASEASS528122  1 67 45 51  4 1716 403  12 211 146 155 209372 17 350
Steve Sax     NLA 2B633210  6 91 56 59  6 3070 872  19 420 230 274 367432 16  90
Tony Armas    ABOSCF 16  2  0  1  0  0  2   28   4   0   1   0   0 247  4  8   .
T Bernazard   ACLE2B562169 17 88 73 53  8 3181 841  61 450 342 373 351442 17 530
Tom Brookens  ADETUT281 76  3 42 25 20  8 2658 657  48 324 300 179 106144  7 342
Tom Brunansky AMINRF593152 23 69 75 53  6 2765 686 133 369 384 321 315 10  6 940
T Fernandez   ATORSS687213 10 91 65 27  4 1518 448  15 196 137  89 294445 13 350
Tim Flannery  NSD 2B368103  3 48 28 54  8 1897 493   9 207 162 198 209246  3 327
Tom Foley     NMONUT263 70  1 26 23 30  4  888 220   9  83  82  86  81147  4 250
Tony Gwynn    NSD RF642211 14107 59 52  5 2364 770  27 352 230 193 337 19  4 740
Terry Harper  NATLOF265 68  8 26 30 29  7 1337 339  32 135 163 128  92  5  3 425
Toby Harrah   ATEX2B289 63  7 36 41 44 17 74021954 1951115 9191153 166211  7   .
Tommy Herr    NSTL2B559141  2 48 61 73  8 3162 874  16 421 349 359 352414  9 925
Tim Hulett    ACHA3B520120 17 53 44 21  4  927 227  22 106  80  52  70144 11 185
Terry Kennedy NSD C  19  4  1  2  3  1  1   19   4   1   2   3   1 692 70  8 920
Tito Landrum  NSTLOF205 43  2 24 17 20  7  854 219  12 105  99  71 131  6  1 287
Tim Laudner   AMINC 193 47 10 21 29 24  6 1136 256  42 129 139 106 299 13  5 245
Tom O'Malley  ABAL3B181 46  1 19 18 17  5  937 238   9  88  95 104  37 98  9   .
Tom Paciorek  ATEXUT213 61  4 17 22  3 17 40611145  83 488 491 244 178 45  4 235
Tony Pena     NPITC 510147 10 56 52 53  7 2872 821  63 307 340 174 810 99 181150
T Pendleton   NSTL3B578138  1 56 59 34  3 1399 357   7 149 161  87 133371 20 160
Tony Perez    NCIN1B200 51  2 14 29 25 23 97782732 37912721652 925 398 29  7   .
Tony Phillips AOAK2B441113  5 76 52 76  5 1546 397  17 226 149 191 160290 11 425
Terry Puhl    NHOUOF172 42  3 17 14 15 10 40861150  57 579 363 406  65  0  0 900
Tim Raines    NMONLF580194  9 91 62 78  8 33721028  48 604 314 469 270 13  6   .
Ted Simmons   NATLUT127 32  4 14 25 12 19 83962402 24210481348 819 167 18  6 500
Tim Teufel    NNYN2B279 69  4 35 31 32  4 1359 355  31 180 148 158 133173  9 278
Tim Wallach   NMON3B480112 18 50 71 44  7 3031 771 110 338 406 239  94270 16 750
Vince Coleman NSTLLF600139  0 94 29 60  2 1236 309   1 201  69 110 300 12  9 160
Von Hayes     NPHI1B610186 19107 98 74  6 2728 753  69 399 366 2861182 96 131300
Vance Law     NMON2B360 81  5 37 44 37  7 2268 566  41 279 257 246 170284  3 525
Wally Backman NNYN2B387124  1 67 27 36  7 1775 506   6 272 125 194 186290 17 550
Wade Boggs    ABOS3B580207  8107 71105  5 2778 978  32 474 322 417 121267 191600
Will Clark    NSF 1B408117 11 66 41 34  1  408 117  11  66  41  34 942 72 11 120
Wally Joyner  ACAL1B593172 22 82100 57  1  593 172  22  82 100  571222139 15 165
W Krenchicki  NMON13221 53  2 21 23 22  8 1063 283  15 107 124 106 325 58  6   .
Willie McGee  NSTLCF497127  7 65 48 37  5 2703 806  32 379 311 138 325  9  3 700
W Randolph    ANYA2B492136  5 76 50 94 12 55111511  39 897 451 875 313381 20 875
W Tolleson    ACHA3B475126  3 61 43 52  6 1700 433   7 217  93 146  37113  7 385
Willie Upshaw ATOR1B573144  9 85 60 78  8 3198 857  97 470 420 3321314131 12 960
Willie Wilson AKC CF631170  9 77 44 31 11 49081457  30 775 357 249 408  4  31000
;

proc summary data=baseball nway;
class league team;
var hits;
output out=mean mean=hits stderr=stderr;
data mean;
set mean;
*err=0.67*stderr; *%50 conf. interal;
err=stderr;
run;

*For demonstration purpose, just draw fewer teams on the y-axis;
data _t_(where=(err^=.));
set mean(obs=100);
run;

*************IMPORTANT!!!!!!: PLEASE MAKE SURE OF THE RANGE OF XORDER IS APPORPRIATE**************************

*this will change the figure size and ticks label font size;
*goptions reset=all ftext='arial' htext=3 gunit=pct;
 *        dev=gif xpixels=800 ypixels=800 gsfname=gout;
*gunit=pct may need to be exclude, since the final figure is distorted;

*%dotplot(data=_t_,xvar=hits,yvar=team,connect=dot);
*Note: connect=zero seems to be malfunctional;

%dotplot(data=_t_,xvar=hits,yvar=team,
          dcolor=green,connect=axis,
		   xorder=70 to 150 by 10,
		  errbar=err,name=GB0220);

*%dotplot(data=_t_, xvar=hits, yvar=team,
          errbar=err, connect=none,
		  dcolor=green, group=league,
		  xorder=70 to 150 by 10,
		  name=GB0221);
*/
