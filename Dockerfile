FROM ubuntu:18.04 as base

RUN apt-get -y update
RUN apt-get -y install git wget 

### DOWNLOAD REQUIRED SOFTWARE

# BLAST+ (PSI-BLAST)
RUN wget -nv https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.9.0/ncbi-blast-2.9.0+-x64-linux.tar.gz
RUN wget -nv https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.9.0/ncbi-blast-2.9.0+-x64-linux.tar.gz.md5
RUN md5sum -c ncbi-blast-2.9.0+-x64-linux.tar.gz.md5

# PROSPER
RUN wget --no-check-certificate -nv https://prosper.erc.monash.edu.au/prosper.tgz

# PSIPRED
RUN wget -nv http://bioinfadmin.cs.ucl.ac.uk/downloads/psipred/psipred.4.02.tar.gz

# DISOPRED
RUN wget -nv http://bioinfadmin.cs.ucl.ac.uk/downloads/DISOPRED/DISOPRED3.16.tar.gz
RUN wget -nv http://bioinfadmin.cs.ucl.ac.uk/downloads/DISOPRED/DISOPRED3.16.tar.gz.MD5
RUN md5sum -c DISOPRED3.16.tar.gz.MD5

# ACCPro
RUN wget -nv http://download.igb.uci.edu/SCRATCH-1D_1.2.tar.gz
RUN wget -nv ftp://ftp.ncbi.nlm.nih.gov/blast/executables/legacy.NOTSUPPORTED/2.2.26/blast-2.2.26-x64-linux.tar.gz

# clean up
RUN mv *.tar.gz *.tgz ~
RUN rm *.md5 *.MD5

### INSTALL REQUIRED SOFTWARE

RUN apt-get install -y vim
RUN echo 'export PATH=$PATH:~/bin:~/SCRATCH-1D_1.2/pkg/ACCpro_5.2/bin:~/prosper' >> ~/.bashrc
RUN mkdir ~/bin
RUN mkdir ~/data

# BLAST+
RUN cd /tmp && tar xf ~/ncbi-blast-2.9.0+-x64-linux.tar.gz && cp ncbi-blast-2.9.0+/bin/* /usr/local/bin/
RUN rm -rf ~/ncbi-blast*

# PSIPRED
RUN apt-get install -y tcsh
RUN cd /tmp && tar xf ~/psipred.4.02.tar.gz && cp psipred/run* psipred/BLAST+/run* psipred/bin/* ~/bin
RUN cd /tmp && cp -r psipred/data ~/data/psipred
RUN rm -rf ~/psipred*

# DISOPRED
RUN apt-get install -y make g++
RUN cd /tmp && tar xf ~/DISOPRED3.16.tar.gz && cd DISOPRED/src && make && make install && cp ../bin/* ~/bin && mv ../data ~/data/disopred
RUN rm -rf ~/DISOPRED*

# ACCPro
RUN cd ~ && tar xf SCRATCH-1D_1.2.tar.gz && cd SCRATCH-1D_1.2 && rm -rf pkg/blast-2.2.26 && tar -C pkg/ -xf ~/blast-2.2.26-x64-linux.tar.gz && perl install.pl
RUN rm -rf ~/SCRATCH*.tar.gz ~/blast*.tar.gz

# prosper
RUN cd ~ && tar xf prosper.tgz && rm prosper.tgz

# DISOPRED library
RUN wget -nv http://bioinfadmin.cs.ucl.ac.uk/downloads/DISOPRED/dso_lib.tar.gz
RUN tar xf dso_lib.tar.gz -C /root/data

### BUILD UNIREF DB

COPY uniref90.fasta.gz /root/data
RUN cd ~/data && gunzip -dv uniref90.fasta.gz && makeblastdb -dbtype prot -in uniref90.fasta -out uniref90

### SVM DEPENDENCY FOR PROSPER

RUN cd ~/prosper && wget http://download.joachims.org/svm_light/current/svm_light_linux64.tar.gz && tar xf svm_light_linux64.tar.gz && rm svm_light_linux64.tar.gz

### COPY SCRIPT & EXAMPLE FILES

COPY protease_prediction.sh /root/bin/
RUN chmod +x ~/bin/protease_prediction.sh
RUN mkdir ~/project
COPY run_disopred_plus.pl /root/bin
COPY run_disopred_plus_multiCoreTest.pl /root/bin

### CONFIGURE PROGRAMS

# PSIPRED
RUN sed -i 's/uniref90filt/\/root\/data\/uniref90/' /root/bin/runpsipredplus
RUN sed -i '20s/\.\.\/bin/\/root\/bin/' /root/bin/runpsipredplus
RUN sed -i '23s/\.\.\/data/\/root\/data\/psipred/' /root/bin/runpsipredplus

### REPLACE PSIBLAST WITH PSIBLAST-CACHE
RUN apt-get install -y python3 python3-pip redis-tools
RUN pip3 install redis
RUN mkdir /root/psiblast_cache
RUN mv /usr/local/bin/psiblast /usr/local/bin/psiblast-uncached
COPY psiblast.py /usr/local/bin/psiblast
RUN chmod +x /usr/local/bin/psiblast

### REPLACE BLASTPGP WITH WRAPPER
RUN mv /root/SCRATCH-1D_1.2/pkg/blast-2.2.26/bin/blastpgp /root/SCRATCH-1D_1.2/pkg/blast-2.2.26/bin/blastpgp-og
COPY blastpgp-wrapper /root/SCRATCH-1D_1.2/pkg/blast-2.2.26/bin/blastpgp
RUN chmod +x /root/SCRATCH-1D_1.2/pkg/blast-2.2.26/bin/blastpgp

### FIX ACCPRO FOR UPDATED ASCII PSSM FORMAT
RUN sed -i '68s/A  R  N  D  C  Q  E/A   R   N   D   C   Q   E/' ~/SCRATCH-1D_1.2/pkg/PROFILpro_1.2/lib/process_full_batch.pl

### DISOPRED permissions
RUN chmod +x /root/bin/run_disopred_plus.pl

