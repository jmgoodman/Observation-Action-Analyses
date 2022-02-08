% MCP variability

mcp1=get(LHO1,'metacarpaljoints');
mcp2=get(LHO2,'metacarpaljoints');
mcp3=get(LHO3,'metacarpaljoints');
mcp4=get(LHO4,'metacarpaljoints');

dist_th(1)=norm(mcp2(1,1:3)-mcp1(1,1:3));
dist_th(2)=norm(mcp3(1,1:3)-mcp2(1,1:3));
dist_th(3)=norm(mcp4(1,1:3)-mcp3(1,1:3));

dist_in(1)=norm(mcp2(2,1:3)-mcp1(2,1:3));
dist_in(2)=norm(mcp3(2,1:3)-mcp2(2,1:3));
dist_in(3)=norm(mcp4(2,1:3)-mcp3(2,1:3));

dist_mi(1)=norm(mcp2(3,1:3)-mcp1(3,1:3));
dist_mi(2)=norm(mcp3(3,1:3)-mcp2(3,1:3));
dist_mi(3)=norm(mcp4(3,1:3)-mcp3(3,1:3));

dist_ri(1)=norm(mcp2(4,1:3)-mcp1(4,1:3));
dist_ri(2)=norm(mcp3(4,1:3)-mcp2(4,1:3));
dist_ri(3)=norm(mcp4(4,1:3)-mcp3(4,1:3));

dist_li(1)=norm(mcp2(5,1:3)-mcp1(5,1:3));
dist_li(2)=norm(mcp3(5,1:3)-mcp2(5,1:3));
dist_li(3)=norm(mcp4(5,1:3)-mcp3(5,1:3));


dist_complete=[dist_th dist_in dist_mi dist_ri dist_li];

mean(dist_complete)
std(dist_complete)

dist_th_in(1)=norm(mcp1(1,1:3)-mcp1(2,1:3));
dist_th_in(2)=norm(mcp2(1,1:3)-mcp2(2,1:3));
dist_th_in(3)=norm(mcp3(1,1:3)-mcp3(2,1:3));
dist_th_in(4)=norm(mcp4(1,1:3)-mcp4(2,1:3));
stddev(1)=std(dist_th_in);

dist_in_mid(1)=norm(mcp1(2,1:3)-mcp1(3,1:3));
dist_in_mid(2)=norm(mcp2(2,1:3)-mcp2(3,1:3));
dist_in_mid(3)=norm(mcp3(2,1:3)-mcp3(3,1:3));
dist_in_mid(4)=norm(mcp4(2,1:3)-mcp4(3,1:3));
stddev(2)=std(dist_in_mid);

dist_mid_rin(1)=norm(mcp1(3,1:3)-mcp1(4,1:3));
dist_mid_rin(2)=norm(mcp2(3,1:3)-mcp2(4,1:3));
dist_mid_rin(3)=norm(mcp3(3,1:3)-mcp3(4,1:3));
dist_mid_rin(4)=norm(mcp4(3,1:3)-mcp4(4,1:3));
stddev(3)=std(dist_mid_rin);

dist_rin_lit(1)=norm(mcp1(4,1:3)-mcp1(5,1:3));
dist_rin_lit(2)=norm(mcp2(4,1:3)-mcp2(5,1:3));
dist_rin_lit(3)=norm(mcp3(4,1:3)-mcp3(5,1:3));
dist_rin_lit(4)=norm(mcp4(4,1:3)-mcp4(5,1:3));
stddev(4)=std(dist_rin_lit);


