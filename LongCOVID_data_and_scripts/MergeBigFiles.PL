#!/usr/bin/perl -w
use warnings;
use strict;
#use Data::Dumper;
print STDERR "\n\nUsage: MergeBigFiles.pl\n",
"1: FileRgx (single quoted perl rgx to match files)\n",
"2: FileDir (directory to parse files)\n",
"3: OutTag  (file output tag)\n",
"4: Header_lineNumber (indicating whether files have header; default=1)\n", 
"5: KeyColNumsUsed4Merge (default=1;if >1 numbers, sep it with comma, such as 1,2,3,-1)\n",
"6: Targeted_data_colnums (optional 1-based cols separated by comma,if supplied, will only print these data columns with keys\n",
"7: sep (default:\\t; if use blank space, double quote it)\n",
"8: file_content_checker_rgx (optional and make sure within all files the rgx can be found)!\n",
"9: remove_file_apendix (default value is 1 to remove file appendx such as .txt, .tsv and others .*, in the header!
   Alternatively, provide 0 to reserve the full filename in the headers.)\n\n\n"
and exit if (@ARGV<3);

my $FileRgx=shift;
my $FileDir=shift;
my $OutTag=shift;
my $header_lnum=shift;
unless (defined $header_lnum) {#Use contents in the line to make headers in output;
	$header_lnum=1;
}

my $KeyColNumUsed4Merge=shift;
if (not defined $KeyColNumUsed4Merge) {#Use contents in the line to make headers in output;
	$KeyColNumUsed4Merge=0;
}else{
     if($KeyColNumUsed4Merge=~/\d+,\d+/){
        my @cs=split(",",$KeyColNumUsed4Merge);
           @cs=map{$_-1 if $_>0}@cs;
        $KeyColNumUsed4Merge=join(",",@cs);
     }else{
	$KeyColNumUsed4Merge-=1 if $KeyColNumUsed4Merge>0;#0-based column number;
        }
}


my $Targeted_data_colnums=shift;#If supplied, will only print these cols with comman keys;
my @tn;
if (defined $Targeted_data_colnums){
   @tn=split(",",$Targeted_data_colnums);
   @tn=map{$_-1 if $_>0}@tn;  
}


my $sep=shift;
if (not defined $sep) {#Use contents in the line to make headers in output;
	$sep="\t";
	print STDERR "Default sep (TAB) is used to separate each col in these files\n";
}else{
	print STDERR "The user defined sep ($sep) is used to separate each col in these files\n";
}

my $cont_rgx=shift;

#opendir(D,"$FileDir") or die "Can not open the $FileDir: $!";
#my @fls=readdir(D);
#   @fls=grep{/$FileRgx/i;} @fls;
#   @fls=map{"$FileDir/$_";}@fls;

chomp(my $inf=`RecursiveSearchDir.pl $FileDir "$FileRgx"`);
my @fls=split("\n",$inf);
   #sort files, important for the order of file headers in the final merged file;
   @fls=sort {$b cmp $a} @fls;

#closedir(D);

print STDERR "Your dir $FileDir does not contain files matched with your regex $FileRgx!\n" and exit if @fls<1;

my @targets=();

if (defined $cont_rgx) {#check all files and make sure each file match the rgx;
undef $/;
foreach my $f (@fls){
open FH,"$f" or die "Couldn\'t open the file: $!";
my $fileinf=<FH>;
push @targets,$f if ($fileinf=~/\b$cont_rgx\b/is);
close FH;
}
}else{
  @targets=@fls;	
}

my $n;
my $x=600;#the number of merged files at once
my $left=@targets % $x;
($left>0) ? ($n=$#targets-$left):($n=$#targets);

for (my $i=0;$i<=$#targets;$i+=$x){
	if ($i>$n){
	print STDERR "These files: \n",join("\n",@targets[$i..$#targets]),"\nwere processed together!\n";
	my @t=@targets[$i..$#targets];
        if (defined $Targeted_data_colnums){
	  MergeFiles(\@t,$i,$header_lnum,$KeyColNumUsed4Merge,$sep,$OutTag,\@tn);
         }else{
	  MergeFiles(\@t,$i,$header_lnum,$KeyColNumUsed4Merge,$sep,$OutTag);
         }
 }else{
 	my $ii=$i+$x-1;
 	my @temp=@targets[$i..$ii];
 	#print join("\n",@temp)," $i $ii\n";
        if (defined $Targeted_data_colnums){       
          MergeFiles(\@temp,$i,$header_lnum,$KeyColNumUsed4Merge,$sep,$OutTag,\@tn);
        }else{
          MergeFiles(\@temp,$i,$header_lnum,$KeyColNumUsed4Merge,$sep,$OutTag);
    }
  }
 }




sub MergeFiles{
 my %exp=();
 my @totalHeaders=();
 my $files_ref=shift;
 my $num=shift;
 my $hd_lnum=shift;
 my $keycolnum=shift;
 my @colnums=split(",",$keycolnum);

 my $sep=shift;
 my $outtag=shift;
 my $tn_ref=shift;#array ref has 0-based column number for output data;
 my @tn;
 if (defined $tn_ref){
    @tn=@{$tn_ref};
 }
 
 my $KeyName="KeyUsed4Merge";
 foreach my $f (@$files_ref){
	my $fn=$f;
	   $fn=~s/^.*\/([^\/]+)/$1/;
	   $fn=~s/\W+/./g;
  	if (-e $f){
	open FH,"$f" or die "Couldn\'t open the expression dataset: $!";
        my $firstline;
        if ($hd_lnum>=1){
	for(my $i=1;$i<=$hd_lnum;$i++){
  	   $firstline=<FH>;#get header line for Headers
	 }
  	chomp($firstline);
       }else{
        #make headers like 'V1','V2' and so on;
        open _FH_,"$f" or die "Couldn\'t open the expression dataset: $!";
        my $tmp_first_line=<_FH_>;
        close _FH_;
        my @tmp1stes=split("$sep",$tmp_first_line);
           $firstline=join("$sep",map{$_++;"V".$_}0..$#tmp1stes);#make fake firstline;

       }

  	my @Headers=split("$sep",$firstline);
	my $Hkey=join(":",@Headers[@colnums]);
	   $KeyName=$Hkey;
        my @hs=@Headers[@colnums];
        my @idx=(0..$#Headers);
           @idx=@tn if (@tn>0);
	my @NonKeyHeaderNums=grep{
              my $e=$Headers[$_];
              my $ex=0;
              foreach my $x(@hs){
                  $ex=1 if $e eq $x;
                  $ex=0 if $e ~~ @Headers[@colnums];#keep these var used for making keys;
              }
              $ex==0
          }@idx;
        my $Headers_tmp;
	if (defined $ARGV[8] and $ARGV[8]==0){
            $Headers_tmp=join("\t",map{$Headers[$_].".FOR.".$fn}@NonKeyHeaderNums);
        }else{
           #Make the header shorter!;
       	   $Headers_tmp=join("\t",map{
                                   $fn=~s/\..*//;
                                   $Headers[$_]."__".$fn
                                   } @NonKeyHeaderNums);
        }
  	push @totalHeaders,$Headers_tmp;
	
  	while (my $line=<FH>){
  		chomp($line);
                next if $line=~/^\s*$/;#escape for blank line;
  		$line=~s/NaN/\./g;
		my @as=split("$sep",$line);
  		my $gene=join(":",@as[@colnums]);
		my @datapoints;
		 @datapoints=@as[@NonKeyHeaderNums];
  		 $exp{$gene}{$Headers_tmp}=join("\t",@datapoints);
    }
    close FH;
   }
  }
   #print Dumper(%exp);
   open OUT,">$outtag.$num.txt" or die "Couldn\'t write data into the file: $!";
   #print OUT "Genesymbol	",join("\t",@GSMInfo{@totalHeaders}),"\n";
   print OUT join("\t",$KeyName,@totalHeaders),"\n";
   foreach my $g (keys %exp){
   	foreach my $TargetCols (@totalHeaders){
   		my @Col_Members=split("\t",$TargetCols);
   		$exp{$g}{$TargetCols}=join("\t",map{"."}0..$#Col_Members) unless (defined $exp{$g}{$TargetCols});
   	}   	
   	my $G=$g;
   	   #$G=~s/\W+/_/g;
   	print OUT $G,"\t",join("\t",@{$exp{$g}}{@totalHeaders}),"\n";
   }
   close OUT;
 }

