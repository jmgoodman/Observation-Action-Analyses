function [joints, angles, helpvector] = calculateJointPhalanxMedialis( ...
    joints,angles,fingerradius,ab,bc,flatf1sens,nopipinversion)  %#eml
%##########################################################################

numJoints=size(joints,1);
A=zeros(3,1);
W=zeros(3,1);
U=zeros(3,1);
helpvector=nan(3,numJoints);

for ff=1:numJoints;
    
    if ~isnan(joints(ff,2,1))
        % SENSOR DATA
        A(:,1)=joints(ff,7,1:3); 
        W(:,1)=joints(ff,2,1:3);
        U(:,1)=joints(ff,3,1:3); 
        AB=ab(ff); 
        BC=bc(ff);

        %JOINTS
        cp1=crossproduct(A-U,A-W); 
        n1=cp1/norm(cp1); 

        % Case when the thumb sensor is flat
        if (flatf1sens && ff == 1)
            R1 = momo(squeeze(joints(ff,1,4:7)),[0;0;0]); % reminder: momo is a function that generates a rotation matrix (or rather a "quaternion" matrix, but honestly if you're doing linear algebra you're missing the point of quaternions)
            V1 = R1*[0;0;1;0];
            cp1 = cross(U-W,V1(1:3)); 
            n1 = cp1/norm(cp1);
        end

        Uh=U+n1; 

        cp3=crossproduct(Uh-U,W-U);
        n3=cp3/norm(cp3);
        C=U+n3*fingerradius(ff);
        T=W+n3*fingerradius(ff);

        ac=C-A;
        AC=norm(C-A);

        alpha=acos((AB^2+AC^2-BC^2)/(2*AB*AC));
        if ~isreal(alpha)
            alpha=0;
        end
        h=sin(alpha)*AB;
        q=cos(alpha)*AB;
        eac=ac/AC;
        L=A+eac*q;
        ang=abs(acos((dot(ac,U-W)/(norm(ac)*norm(U-W)))));
        if ang<= 0.12 
            B=L;
            warning('Unknown condition\n');
        else
            Lh=L+n1; 


            cp2=crossproduct(Lh-A,L-A);
            n2=(cp2/norm(cp2));

            Bs1=n2*h+L;
            Bs2=(n2*(-1)*h)+L;

            % this part selects the candidate furthest from the tip as B            
            sb1=norm(Bs1-T);
            sb2=norm(Bs2-T);
            
            if nopipinversion
                B=Bs2;
            else
                if sb1>sb2
                    B=Bs1;
                else
                    B=Bs2;
                end
            end

            if ~isreal(alpha) && ff==2
                B=A+eac*(AC/(1+fakt));
            end

        end

        joints(ff,6,1:3)=B; 
        joints(ff,4,1:3)=T;
        joints(ff,5,1:3)=C;
        
        helpvector(:,ff)=A+n1*20;

    else
        joints(ff,4,1:3)=NaN;  % T
        joints(ff,5,1:3)=NaN;  % C
        joints(ff,6,1:3)=NaN;  % B
        angles(ff,1)=NaN;
        angles(ff,2)=NaN;
        angles(ff,3)=NaN;
        angles(ff,4)=NaN;
        
    end  
end

end
