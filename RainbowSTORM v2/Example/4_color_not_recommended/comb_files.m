fnam0=['p750p019_zeroth_1'];
fname0=sprintf('%s.csv',fnam0);
TR01=csvread(fname0,1,0);

fnam0=['p750p019_zeroth_2'];
fname0=sprintf('%s.csv',fnam0);
TR02=csvread(fname0,1,0);

fnam0=['p750p019_zeroth_3'];
fname0=sprintf('%s.csv',fnam0);
TR03=csvread(fname0,1,0);

fnam0=['p750p019_zeroth_4'];
fname0=sprintf('%s.csv',fnam0);
TR04=csvread(fname0,1,0);

fnam0=['p750p019_zeroth_5'];
fname0=sprintf('%s.csv',fnam0);
TR05=csvread(fname0,1,0);

fnam0=['p750p019_zeroth_6'];
fname0=sprintf('%s.csv',fnam0);
TR06=csvread(fname0,1,0);

fnam0=['p750p019_zeroth_7'];
fname0=sprintf('%s.csv',fnam0);
TR07=csvread(fname0,1,0);

fnam0=['p750p019_zeroth_8'];
fname0=sprintf('%s.csv',fnam0);
TR08=csvread(fname0,1,0);

fnam0=['p750p019_zeroth_9'];
fname0=sprintf('%s.csv',fnam0);
TR09=csvread(fname0,1,0);

fnam0=['p750p019_zeroth_10'];
fname0=sprintf('%s.csv',fnam0);
TR010=csvread(fname0,1,0);

TR0=[TR01;TR02;TR03;TR04;TR05;TR06;TR07;TR08;TR09;TR010];

A6={'id','frame','x [nm]','y [nm]','sigma [nm]','intensity [photon]','offset [photon]','bgstd [photon]','uncertainty [nm]'};

savefile='p750p019_zeroth.csv';
writecell(A6,savefile)
dlmwrite(savefile,TR0,'delimiter',',','-append');
%%
fnam0=['p750p019_first_1'];
fname0=sprintf('%s.csv',fnam0);
TR11=csvread(fname0,1,0);

fnam0=['p750p019_first_2'];
fname0=sprintf('%s.csv',fnam0);
TR12=csvread(fname0,1,0);

fnam0=['p750p019_first_3'];
fname0=sprintf('%s.csv',fnam0);
TR13=csvread(fname0,1,0);

fnam0=['p750p019_first_4'];
fname0=sprintf('%s.csv',fnam0);
TR14=csvread(fname0,1,0);
TR1=[TR11;TR12;TR13;TR14];

A6={'id','frame','x [nm]','y [nm]','z [nm]','sigma1 [nm]','sigma2 [nm]','intensity [photon]','offset [photon]','bgstd [photon]','uncertainty [nm]'};

savefile='p750p019_first.csv';
writecell(A6,savefile)
dlmwrite(savefile,TR1,'delimiter',',','-append');