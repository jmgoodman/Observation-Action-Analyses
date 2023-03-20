SELECT Zara70.`M1-med`.*,
Zara70.`M1-lat`.*,
Zara70.Index_Info.Alignment,
Zara70.Trial_Info.Object,
Zara70.Trial_Info.Context
FROM Zara70.`M1-med`
LEFT JOIN Zara70.`M1-lat`
ON Zara70.`M1-med`.index=Zara70.`M1-lat`.index
LEFT JOIN Zara70.Index_Info
ON Zara70.`M1-med`.index=Zara70.Index_Info.index
LEFT JOIN Zara70.Trial_Info
ON Zara70.`M1-med`.Trial=Zara70.Trial_Info.Trial;