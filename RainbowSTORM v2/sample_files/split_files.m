fnam1=['p750p019_first2'];
fnam0=['p750p019_zeroth'];

fname0=sprintf('%s.csv',fnam0);
fname1=sprintf('%s.csv',fnam1);
% fname1='still_first.csv';
% fname0='still.csv';
TR0=csvread(fname0,1,0);
TR1=csvread(fname1,1,0);

%%
A6={'id','frame','x [nm]','y [nm]','sigma [nm]','intensity [photon]','offset [photon]','bgstd [photon]','uncertainty [nm]'};


savefile='p750p019_zeroth_1.csv';
writecell(A6,savefile)
dlmwrite(savefile,TR0(1:671507,:),'delimiter',',','-append');

savefile='p750p019_zeroth_2.csv';
writecell(A6,savefile)
dlmwrite(savefile,TR0(671508:1343013,:),'delimiter',',','-append');

savefile='p750p019_zeroth_3.csv';
writecell(A6,savefile)
dlmwrite(savefile,TR0(1343014:2014519,:),'delimiter',',','-append');

savefile='p750p019_zeroth_4.csv';
writecell(A6,savefile)
dlmwrite(savefile,TR0(2014520:2686025,:),'delimiter',',','-append');

savefile='p750p019_zeroth_5.csv';
writecell(A6,savefile)
dlmwrite(savefile,TR0(2686026:3357531,:),'delimiter',',','-append');

savefile='p750p019_zeroth_6.csv';
writecell(A6,savefile)
dlmwrite(savefile,TR0(3357532:4029037,:),'delimiter',',','-append');

savefile='p750p019_zeroth_7.csv';
writecell(A6,savefile)
dlmwrite(savefile,TR0(4029038:4700543,:),'delimiter',',','-append');

savefile='p750p019_zeroth_8.csv';
writecell(A6,savefile)
dlmwrite(savefile,TR0(4700544:5372049,:),'delimiter',',','-append');

savefile='p750p019_zeroth_9.csv';
writecell(A6,savefile)
dlmwrite(savefile,TR0(5372050:6043555,:),'delimiter',',','-append');

savefile='p750p019_zeroth_10.csv';
writecell(A6,savefile)
dlmwrite(savefile,TR0(6043556:6715065,:),'delimiter',',','-append');
%%
A6={'id','frame','x [nm]','y [nm]','z [nm]','sigma1 [nm]','sigma2 [nm]','intensity [photon]','offset [photon]','bgstd [photon]','uncertainty [nm]'};


savefile='p750p019_first_1.csv';
writecell(A6,savefile)
dlmwrite(savefile,TR1(1:500000,:),'delimiter',',','-append');

savefile='p750p019_first_2.csv';
writecell(A6,savefile)
dlmwrite(savefile,TR1(500001:1000000,:),'delimiter',',','-append');

savefile='p750p019_first_3.csv';
writecell(A6,savefile)
dlmwrite(savefile,TR1(1000001:1500000,:),'delimiter',',','-append');

savefile='p750p019_first_4.csv';
writecell(A6,savefile)
dlmwrite(savefile,TR1(1500001:end,:),'delimiter',',','-append');

