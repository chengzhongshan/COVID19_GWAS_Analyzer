# COVID19_GWAS_Analyzer


![image](https://github.com/chengzhongshan/COVID19_GWAS_Analyzer/assets/24280206/3f28404f-0cc4-4c91-aef7-ef6594a8f338)

This package provides SAS scripts that perform differential effect size analysis between two COVID19 GWASs freely available from HGI or GRASP databases. Users need to have an account of SAS OnDemand for Academics, which can be freely accessed here (https://www.sas.com/en_us/software/on-demand-for-academics.html). 

Once users have the free SAS account, they can login into the SAS OnDemand for Academics and install our package by following one of the two steps:

####################################################################################

EASY IMPLEMENTATION OF COVID19_GWAS_ANALYZER

To install and load the necessary SAS macros from COVID19_GWAS_Aanalyzer, users can execute the following commands in SAS Studio:

   filename M url "https://raw.githubusercontent.com/chengzhongshan/COVID19_GWAS_Analyzer/main/Macros/importallmacros_ue.sas";
   
   %include M;
   
   Filename M clear;
   
   %importallmacros_ue(MacroDir=%sysfunc(pathname(HOME))/Macros,fileRgx=.,verbose=0); 
   
These macros streamline various aspects of GWAS analysis, including data preparation, statistical comparisons, and visualization. The macro “%importallmacros_ue” ensures that all functions needed for analyses are available. 
If users want to run COVID19_GWAS_Analyzer locally using SAS 9.4 workbench in Windows or Linux, please download all macros provided by COVID19_GWAS_Analyzer from github and add the ‘Macros’ directory into the macro searching path by running the code as follows:

   options insert=(sasautos=”path2MacrosDirectory”);
   
   %importallmacros(MacroDir=path2MacrosDirectory);
   
Note: a handy macro called “%macroparas(macrorgx=regular_expression2macro)” can be used to print contents of each macro.

####################################################################################

MANUAL IMPLEMENTATION OF COVID19_GWAS_ANALYZER 

After logging into the SAS studio of SAS OnDemand for Academics, please create a directory called 'Macros' under the 'HOME' directory (such as /home/username) of the account. Please upload all SAS macros shared in the 'Macros' directory in this package. These macros will be used by the shared SAS scripts to download GWAS data from the HGI or GRASP databases, perform GWAS comparison, draw Manhattan plot and QQ plot, and conduct single cell expression analyses with data shared by UCSC Cell Browser.

####################################################################################

Please read our iScience ans STAR Protocol papers, as well as the SAS SESUG2024 conferennce paper for how we used the COVID19_GWAS_Analyzer to perform intergative GWAS analysis.

https://www.sciencedirect.com/science/article/pii/S2589004223016322

https://www.sciencedirect.com/science/article/pii/S266616672400193X

https://www.lexjansen.com/sesug/2024/151_Final_PDF.pdf

Please read the annotations for all SAS macros included in the "Macros" directory.
https://github.com/chengzhongshan/COVID19_GWAS_Analyzer/blob/main/Macros/Available_SAS_Macros_and_its_annotations4STAR_PROTOCOL.csv


####################################################################################

Demonstration codes for the investigation of a regulatory SNP of MAP3K19 predisposing to COVID-19 hospitalization specific to populations with African ancestry.



%let macrodir=%sysfunc(pathname(HOME))/Macros;

%include "&macrodir/importallmacros_ue.sas";

%importallmacros_ue;

####################################################################################

*Step1;

%GRASP_COVID_Hosp_GWAS_Comparison(

gwas1=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/10202020/COVID19_HGI_B1_ALL_20201020.b37.txt.gz,

gwas2=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/10202020/COVID19_HGI_B2_ALL_leave_23andme_20201020.b37.txt.gz,

outdir=%sysfunc(pathname(HOME)),

mk_manhattan_qqplots4twoGWASs=1 

);

*Expected figures:;
![Slide1](https://github.com/chengzhongshan/COVID19_GWAS_Analyzer/assets/24280206/39574778-3671-4135-83ae-56af551dea70)
![Slide2](https://github.com/chengzhongshan/COVID19_GWAS_Analyzer/assets/24280206/c0284a36-1bfb-43b2-ac86-ea6e2e433ea1)
![Slide3](https://github.com/chengzhongshan/COVID19_GWAS_Analyzer/assets/24280206/8b2e5cfe-afca-4a9e-a67c-a900c9e36ade)
![Slide4](https://github.com/chengzhongshan/COVID19_GWAS_Analyzer/assets/24280206/2b52f7dd-9ea9-4615-8077-54e545f73b29)
![Slide5](https://github.com/chengzhongshan/COVID19_GWAS_Analyzer/assets/24280206/31e65af4-fcec-465d-a52d-88f059964fe6)

####################################################################################

*Step2;

libname D "%sysfunc(pathname(HOME))";

%Manhattan4DiffGWASs(

dsdin=D.GWAS1_vs_2,

pos_var=pos,

chr_var=chr,

P_var=GWAS1_P,

Other_P_vars=GWAS2_P Pval

);

####################################################################################

*Step3;

libname D "%sysfunc(pathname(HOME))";

*It is only needed to run once for importing the hg19 GTF file;

%let gtf_gz_url=https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_19/gencode.v19.annotation.gtf.gz;

/* %debug_macro; */

%get_genecode_gtf_data(

gtf_gz_url=&gtf_gz_url,

outdsd=D.GTF_HG19

);

####################################################################################

*Step4;

*Previously generated SAS data set GWAS1_vs_2 is stored in the SAS library ‘D’.;

*For SNP_IDs, if providing chr:pos or chr:st:end, it will query by positions ranging from start to end positions on the specific chromosome;

*For ZscoreVars, it can be beta1 beat2 or other numeric vars indicating assoc or other +/- directions;


%SNP_Local_Manhattan_With_GTF(

gwas_dsd=D.GWAS1_vs_2,

chr_var=chr,

AssocPVars=GWAS1_P GWAS2_P pval,

SNP_IDs=rs16831827,


SNP_Var=rsid,

Pos_Var=pos,

gtf_dsd=D.GTF_HG19,

ZscoreVars=GWAS1_z GWAS2_z diff_zscore,


gwas_labels_in_order=HGI_B1 HGI_B2 HGI_B1_vs_B2,

design_width=1300, 

design_height=750

);

*Expected figures for Step 2 to 4;
![Slide6](https://github.com/chengzhongshan/COVID19_GWAS_Analyzer/assets/24280206/983ffe35-e137-4eb4-b48b-0edb992bb1d0)

####################################################################################

*Step5;

%CaculateMulteQTLs_in_GTEx(

query_snps=rs16831827,

gene=MAP3K19,

genoexp_outdsd=geno_exp,

eQTLSumOutdsd=AssocSummary,

create_eqtl_boxplots=1

);

*Expected figures:;
![Slide7](https://github.com/chengzhongshan/COVID19_GWAS_Analyzer/assets/24280206/88b6ef9a-0e7d-4e5a-bf6b-02be42ffd9c8)

####################################################################################

*Step6;

*Download the following single-cell data from UCSC Cell Browser into a local computer and then upload them into the HOME directory of SAS OnDemand for Academics;

* https://cells.ucsc.edu/covid-hypertension/Seurat_umap.coords.tsv.gz;
* https://cells.ucsc.edu/covid-hypertension/meta.tsv;
* https://cells.ucsc.edu/covid-hypertension/exprMatrix.tsv.gz;

%import_sc_mtex_meta_umap_data(

umap_file=%sysfunc(pathname(HOME))/Seurat_umap.coords.tsv.gz,

meta_file=%sysfunc(pathname(HOME))/meta.tsv,

cell_id_in_meta=cell,

exp_matrix_file=%sysfunc(pathname(HOME))/exprMatrix.tsv.gz,

outdir=%sysfunc(pathname(HOME)), 

/*Three sas data sets will be created and put into the dir:

exp (read matrix with column headers, and the last column is for genesymbol), 

umap (umap coordinates with sample meta data merged), 

headers (cell barcodes corresponding to column headers for the exp matrix)*/

target_genes=, 

/*Provide genesymbols separated by | for parsing lines match with these genes;

when the single cell data set is too large, this will save disk space in SAS OnDemand for Academics*/

mean_exp_cutoff=0.01, /*Only keep row records with mean read of gene expression > mean_exp_cutoff*/

max_cells2import=1000000 /*Maximum number of cells to be imported;

if there are more than 1 million cells in the input cell matrix, only 1 million cells

will be randomly selected.*/

);

*Note: if the total number of cells in the matrix is more than 1 million, the macro will randomly select 1 million cells automatically, which will avoid using up the limited disk space (~5GB) in SAS OnDemand for Academics.

####################################################################################

*Step7;

libname sc "%sysfunc(pathname(HOME))";

%sc_umap(

umap_ds=sc.umap,

xvar=x,

yvar=y,

cluster_var=cluster

);

####################################################################################

*Step8;

libname sc "%sysfunc(pathname(HOME))";

*Modify phenotype categories;

data sc.umap;

set sc.umap;

if severity="control_healthy" then severity="Healthy";

if severity="severe" then severity="Severe";

if severity="critical" then severity="Critical";

run;

%sc_scatter4gene(

dsd=sc.exp,

dsd_headers=sc.headers,

dsd_umap=sc.umap,

gene=MAP3K19,

pheno_var=severity,

pheno_categories=Healthy Severe Critical,

boxplot_width=800,

boxplot_height=300,

umap_width=400,

umap_height=800,

umap_lattice_nrows=3,

boxplot_nrows=1,

where_cnd4sgplot=%quote(cluster contains %'Ciliated%')

);

*Further zoom into specific UMAP area defined by the X- and Y-axis regions for the single cells mainly express MAP3K19;

*Note: the input SAS data set "new__tgt_dsd_" is internally generated by the above SAS macro; 

%umap_with_axes_restriction(

dsdin=new__tgt_dsd_,

umap_width=400,

umap_height=800,

lattice_or_not=0,

raxis_max=20000,

raxis_min=0,

caxis_max=,

caxis_min=45000,

panel_row_num=3,

noheader=0

);

*Use the dataset "new__tgt_dsd_" internally generated by running;

*the SAS macro sc_scatter4gene;

*The following steps combine non-ciliated cells as "Other" and 

*treat samples with age>60 as "Yes" and others as "No".;


data tgt;

length cell_type $50.;

set new__tgt_dsd_;

cell_type="Other";

if prxmatch('/Ciliated/i',Cluster) then cell_type=Cluster;

if age>60 then old='Yes';

else Old='No';

run;

*Get percentage of different cells in the single cell data set;

*Note: we use the exp_cutoff=-1;

*This will calculate the percentages of different cells within each pheno group;

*percent=cells/total_cells_in_a_pheno_grp;

*The macro also perform differential gene expression analysis based on log10(reads+1)!;

%sc_freq_boxplot(

longformdsd=tgt,

cell_type_var=cell_type,

sample_grp_var=sample,

pheno_var=severity,

cust_pheno_order=Healthy Severe Critical,

exp_var=exp,

exp_cutoff=-1,

boxplot_height=800,

boxplot_width=300,

boxplot_nrows=5,

where_cnd_for_sgplot=%quote( cell_type contains 'Ciliated' or cell_type='Other'),

frqout=cellfrqout,

other_glm_classes=sex medication Old CAD CVD hypertension,/*covariant for the linear model*/

aggre_sc_glm_pdiff_dsd=all_sc

);

*Expected figures from Step 6 to 8:;
![Slide8](https://github.com/chengzhongshan/COVID19_GWAS_Analyzer/assets/24280206/eb03e911-ebe9-4f47-8b95-7ac111f6bf23)



