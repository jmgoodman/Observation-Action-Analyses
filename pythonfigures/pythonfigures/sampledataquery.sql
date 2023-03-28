select Zara70.`M1-lat`.*, 
Zara70.Index_Info.*, 
Zara70.Trial_Info.* 
FROM Zara70.`M1-lat` 
left join Zara70.Index_Info 
on Zara70.Index_Info.index=Zara70.`M1-lat`.index 
left join Zara70.Trial_Info on Zara70.Trial_Info.Trial=Zara70.`M1-lat`.Trial
order by Zara70.Trial_Info.Trial;