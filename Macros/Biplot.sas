
%macro Biplot(
        data=_LAST_,     /* Data set for Biplot                      */
        var =_NUMERIC_,  /* Variables for Biplot                     */
        id  =ID,         /* Observation ID variable                  */
        dim =2,          /* Number of Biplot dimensions              */
        factype=SYM,     /* Biplot factor type: GH, SYM, or JK       */
        scale=1,         /* Scale factor for variable vectors        */
        out =BIPLOT,     /* Output dataset: Biplot coordinates       */
        anno=BIANNO,     /* Output dataset: annotate labels          */
        std=MEAN,        /* How to standardize columns: NONE|MEAN|STD*/
        pplot=YES);      /* Produce printer plot?                    */

%let factype=%upcase(&factype);
      %if &factype=GH  %then %let p=0;
%else %if &factype=SYM %then %let p=.5;
%else %if &factype=JK  %then %let p=1;
%else %do;
   %put BIPLOT: FACTYPE must be GH, SYM, or JK. "&factype" is not valid.;
   %goto done;
   %end;

Proc IML;
Start Biplot(Y,ID,VARS,OUT, power, scale);
   N = nrow(Y);
   P = ncol(Y);
   %if &std = NONE
       %then Y = Y - Y[:] %str(;);             /* remove grand mean */
       %else Y = Y - J(N,1,1)*Y[:,] %str(;);   /* remove column means */
   %if &std = STD %then %do;
      S = sqrt(Y[##,] / (N-1));
      Y = Y * diag (1 / S );
   %end;

   *-- Singular value decomposition:
        Y is expressed as U diag(Q) V prime
        Q contains singular values, in descending order;
   call svd(u,q,v,y);

   reset fw=8 noname;
   percent = 100*q##2 / q[##];
      *-- cumulate by multiplying by lower triangular matrix of 1s;
   j = nrow(q);
   tri= (1:j)`*repeat(1,1,j)  >= repeat(1,j,1)*(1:j) ;
   cum = tri*percent;
   c1={'Singular Values'};
   c2={'Percent'};
   c3={'Cum % '};
   Print "Singular values and variance accounted for",,
         q       [colname=c1 format=9.4                    ]
         percent [colname=c2 format=8.2         ]
         cum     [colname=c3 format=8.2         ];

   d = &dim ;
   *-- Extract first  d  columns of U & V, and first  d  elements of Q;
   U = U[,1:d];
   V = V[,1:d];
   Q = Q[1:d];

   *-- Scale the vectors by QL, QR;
   * Scale factor 'scale' allows expanding or contracting the variable
     vectors to plot in the same space as the observations;
   QL= diag(Q ## power );
   QR= diag(Q ## (1-power));
   A = U * QL;
   B = V * QR # scale;
   OUT=A // B;

   *-- Create observation labels;
   id = id // vars`;
   type = repeat({"OBS "},n,1) // repeat({"VAR "},p,1);
   id  = concat(type, id);

   factype = {"GH" "Symmetric" "JK"}[1 + 2#power];
   print "Biplot Factor Type", factype;

   cvar = concat(shape({"DIM"},1,d), char(1:d,1.));
   print "Biplot coordinates",
         out[rowname=id colname=cvar];
   %if &pplot = YES %then
   call pgraf(out,substr(id,5),'Dimension 1', 'Dimension 2', 'Biplot');
      ;
   create &out  from out[rowname=id colname=cvar];
   append from out[rowname=id];
finish;

   use &data;
   read all var{&var} into y[colname=vars rowname=&id];
   power = &p;
   scale = &scale;
   run Biplot(y, &id,vars,out, power, scale );
   quit;

 /*----------------------------------*
  |  Split ID into _TYPE_ and _NAME_ |
  *----------------------------------*/
data &out;
   set &out;
   drop id;
   length _type_ $3 _name_ $16;
   _type_ = scan(id,1);
   _name_ = scan(id,2);
 /*--------------------------------------------------*
  | Annotate observation labels and variable vectors |
  *--------------------------------------------------*/
data &anno;
   set &out;
   length function text $8;
   xsys='2'; ysys='2';
   text = _name_;

   if _type_ = 'OBS' then do;         /* Label the observation   */
      color='BLACK';
      x = dim1; y = dim2;
      position='5';
      function='LABEL   '; output;
      end;

   if _type_ = 'VAR' then do;           /* Draw line from     */
      color='RED  ';
      x = 0; y = 0;                     /* the origin to      */
      function='MOVE'    ; output;
      x = dim1; y = dim2;               /* the variable point */
      function='DRAW'    ; output;
      if dim1 >=0
         then position='6';             /* left justify       */
         else position='2';             /* right justify      */
      function='LABEL   '; output;      /* variable name      */
      end;
	  run;

 proc gplot data=Biplot;
 plot Dim1*Dim2/anno=&anno vref=0 href=0;
 symbol1 v=diamond c=blue;
 run;

%done:

%mend;

*data a;
*do ID='A','B','C','D','E','F','H';
* do rep=1 to 5;
*  value=rannor(100);
*  output;
*  end;
*end;
*
*run;
*%Biplot(
*        data=_LAST_,     /* Data set for Biplot                      */
*        var =value rep,  /* Variables for Biplot                     */
*        id  =ID,         /* Observation ID variable                  */
*        dim =2,          /* Number of Biplot dimensions              */
*        factype=SYM,     /* Biplot factor type: GH, SYM, or JK       */
*        scale=1,         /* Scale factor for variable vectors        */
*        out =BIPLOT,     /* Output dataset: Biplot coordinates       */
*        anno=BIANNO,     /* Output dataset: annotate labels          */
*        std=STD,        /* How to standardize columns: NONE|MEAN|STD*/
*        pplot=YES);      /* Produce printer plot?                    */
*  
*
