function [] = updatehistory(h,string)

history=get(h,'String');
idx=numel(history)+1;
history{idx}=string;
set(h,'String',history);
set(h,'Value',idx);