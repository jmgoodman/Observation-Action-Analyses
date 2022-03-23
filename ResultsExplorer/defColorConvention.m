function colorStruct = defColorConvention()
colorConvention = lines(4);

colorConvention = colorConvention( [4,2,1],: );
colorConvention = vertcat([0 0 0],colorConvention); % order: pooled, AIP, F5, M1

colorStruct.colors = colorConvention;
colorStruct.labels = {'pooled','AIP','F5','M1'};

return