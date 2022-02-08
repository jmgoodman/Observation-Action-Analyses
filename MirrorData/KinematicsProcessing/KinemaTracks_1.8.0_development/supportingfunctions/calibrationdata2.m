function [calibdata]=calibrationdata2(~,GHO,calibdata,kk,finger,depth)

reference=GHO.reference;
Mlg = momo_mex(reference(1,4:7),reference(1,1:3));
armjoints=GHO.armjoints;
calibcart=armjoints(1,1:3);
calibquat=armjoints(1,4:7);
caliblocal=[0,0,depth];
calibglobal=momo(calibquat,calibcart)*[caliblocal(1:3)';1];
caliblocal=Mlg\[calibglobal(1);calibglobal(2);calibglobal(3);1];

calibdata(kk,finger,1:3)=caliblocal(1:3);