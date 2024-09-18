%macro remove_wrd(
sntnc, /*input sentence containing words*/
wrd	 /*target word to be removed from the input sentence;
note: the macro will add space before the target wrd for matching 
it in the sentence, and then remove it!*/
);
 %let sentence=%str( )%nrbquote(&sntnc); 
 %if &sentence^=%str( ) %then %do;
    %let word=%str( )%nrbquote(&wrd);
    %let answer=;
    %let i=%index(&sentence,&word);
    %if &i and &word^=%str( ) %then %do;
       %if &i>1 %then %let answer=%qsubstr(&sentence,1,&i-1);
       %let j=%eval(&i+%index(%qsubstr(&sentence,&i+1),%str( )));
       %if &j>&i %then
       %let answer=&answer%qsubstr(&sentence,&j);
    %end;
    %else %let answer=&sentence;
    %unquote(&answer)
 %end;
%mend ;
/*Demo codes:;

%let new_sntnce=%remove_wrd(
sntnc=I am here for testing!,
wrd=here
);
%put &new_sntnce;

*/
