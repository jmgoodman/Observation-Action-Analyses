GU=importdata('REC36_GUI_90-100.mot');
CL=importdata('REC36_CL_0-1000.mot');

GU.textdata{3,1}=CL.textdata{3,1};
CL.colheaders=GU.colheaders;
CL.textdata=GU.textdata;

data=zeros(size(CL.data,1),291);
data(1:size(CL.data,1),1:size(CL.data,2))=CL.data;

CL.data=data;

TE=CL;

filename='REC_test5.mot';
fid=fopen(filename,'w');

% 4th line of header

for yy=1:size(TE.textdata,1)
    for xx=1:size(TE.textdata,2)
        fprintf(fid,'%c',TE.textdata{yy,xx});
        fprintf(fid,'\t');
    end
    fprintf(fid,'%c\r\n','');
end

for dd=1:size(data,1)
    fprintf(fid, '%f\t', TE.data(dd,:));
    fprintf(fid, '%c\r\n','');
end


fclose(fid);


% dlmwrite(filename, TE.data,'-append','delimiter','\t','roffset', 6,'coffset',0,'precision','%f');
% 
% 
