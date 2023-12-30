# COVID19_GWAS_Analyzer


![image](https://github.com/chengzhongshan/COVID19_GWAS_Analyzer/assets/24280206/3f28404f-0cc4-4c91-aef7-ef6594a8f338)

This package provides SAS scripts that perform differential effect size analysis between two COVID19 GWASs freely available from HGI or GRASP databases. Users need to have an account of SAS OnDemand for Academics, which can be freely accessed here (https://www.sas.com/en_us/software/on-demand-for-academics.html). 

Once users have the free SAS account, they can login into the SAS OnDemand for Academics and create a directory called 'Macros' under the 'HOME' directory (such as /home/username) of the account. Please upload all SAS macros shared in the 'Macros' directory in this package. These macros will be used by the shared SAS scripts to download GWAS data from the HGI or GRASP databases, perform GWAS comparison, draw Manhattan plot and QQ plot, and conduct single cell expression analyses with data shared by UCSC Cell Browser.

Please read our iScience paper for how we used the COVID19_GWAS_Analyzer to perform intergative GWAS analysis.
https://www.sciencedirect.com/science/article/pii/S2589004223016322

Please read the annotations for all SAS macros included in the "Macros" directory.
https://github.com/chengzhongshan/COVID19_GWAS_Analyzer/blob/main/Macros/Available_SAS_Macros_and_its_annotations4STAR_PROTOCOL.csv

