function M=momo(Q,S)  

Q0=Q(1);
Qx=Q(2);
Qy=Q(3);
Qz=Q(4);
Sx=S(1);
Sy=S(2);
Sz=S(3);


M00 = (Q0 * Q0) + (Qx * Qx) - (Qy * Qy) - (Qz * Qz);
M01 = 2 * ((Qx * Qy) - (Q0 * Qz));
M02 = 2 * ((Qx * Qz) + (Q0 * Qy));
M10 = 2 * ((Qx * Qy) + (Q0 * Qz));
M11 = (Q0 * Q0) - (Qx * Qx) + (Qy * Qy) - (Qz * Qz);
M12 = 2 * ((Qy * Qz) - (Q0 * Qx));
M20 = 2 * ((Qx * Qz) - (Q0 * Qy));
M21 = 2 * ((Qy * Qz) + (Q0 * Qx));
M22 = (Q0 * Q0) - (Qx * Qx) - (Qy * Qy) + (Qz * Qz);

M = [M00 M01 M02 Sx; M10 M11 M12 Sy; M20 M21 M22 Sz;0 0 0 1];
