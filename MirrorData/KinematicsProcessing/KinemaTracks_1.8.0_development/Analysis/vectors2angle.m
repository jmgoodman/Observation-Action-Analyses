function angle = vectors2angle(v1,v2)

% angle= rad2deg(atan2(v2(2),v2(1)) - atan2(v1(2),v1(1)));


if ~(isnan(v1(1)) || isnan(v1(2)) || isnan(v2(1)) || isnan(v2(1)))
% Vector 1
if v1(1)==0 || v1(2)==0
    if v1(1)==0
        if v1(2)/abs(v1(2))==1
         sec(1)=4;
        else
         sec(1)=2;
        end
    elseif v1(2)==0;
        if v1(1)/abs(v1(1))==1
            sec(1)=1;
        else
            sec(1)=3;
        end
    end
else

    s11=v1(1)/abs(v1(1));
    s12=v1(2)/abs(v1(2));

    if s11==1 && s12==1
        sec(1)=1;

    elseif s11==1 && s12==-1
        sec(1)=2;
    elseif s11==-1 && s12==-1
        sec(1)=3;
    elseif s11==-1 && s12==1
        sec(1)=4;
    end
end

% Vector 2
if v2(1)==0 || v2(2)==0
    if v2(1)==0
        if v2(2)/abs(v2(2))==1
         sec(2)=4;
        else
         sec(2)=2;
        end
    elseif v2(2)==0;
        if v2(1)/abs(v2(1))==1
            sec(2)=1;
        else
            sec(2)=3;
        end
    end
else

    s11=v2(1)/abs(v2(1));
    s12=v2(2)/abs(v2(2));

    if s11==1 && s12==1
        sec(2)=1;

    elseif s11==1 && s12==-1
        sec(2)=2;
    elseif s11==-1 && s12==-1
        sec(2)=3;
    elseif s11==-1 && s12==1
        sec(2)=4;
    end
end

switch sec(1)
    case 1
        if sec(2)==4
            sign=-1;
        elseif sec(2)==2
            sign=+1;
        elseif sec(2)==1
            refvec=[1 0 0];
            if atan2(norm(cross(refvec,v1)),dot(refvec,v1)) >= atan2(norm(cross(refvec,v2)),dot(refvec,v2))
                sign=1;
            else
                sign=-1;
            end
        elseif sec(2)==3
            refvec=[0 -1 0];
            if atan2(norm(cross(refvec,-1*v1)),dot(refvec,-1*v1)) >= atan2(norm(cross(refvec,v2)),dot(refvec,v2))
                sign=1;
            else
                sign=-1;
            end
        end
    case 2
        if sec(2)==1
            sign=-1;
        elseif sec(2)==3
            sign=+1;
        elseif sec(2)==2
            refvec=[0 -1 0];
            if atan2(norm(cross(refvec,v1)),dot(refvec,v1)) >= atan2(norm(cross(refvec,v2)),dot(refvec,v2))
                sign=1;
            else
                sign=-1;
            end
        elseif sec(2)==4
            refvec=[-1 0 0];
            if atan2(norm(cross(refvec,-1*v1)),dot(refvec,-1*v1)) >= atan2(norm(cross(refvec,v2)),dot(refvec,v2))
                sign=1;
            else
                sign=-1;
            end
        end
    case 3
        if sec(2)==2
            sign=-1;
        elseif sec(2)==4
            sign=+1;
        elseif sec(2)==3
            refvec=[-1 0 0];
            if atan2(norm(cross(refvec,v1)),dot(refvec,v1)) >= atan2(norm(cross(refvec,v2)),dot(refvec,v2))
                sign=1;
            else
                sign=-1;
            end
        elseif sec(2)==1
            refvec=[0 1 0];
            if atan2(norm(cross(refvec,-1*v1)),dot(refvec,-1*v1)) >= atan2(norm(cross(refvec,v2)),dot(refvec,v2))
                sign=1;
            else
                sign=-1;
            end
        end
    case 4
        if sec(2)==3
            sign=-1;
        elseif sec(2)==1
            sign=+1;
        elseif sec(2)==4
            refvec=[0 1 0];
            if atan2(norm(cross(refvec,v1)),dot(refvec,v1)) >= atan2(norm(cross(refvec,v2)),dot(refvec,v2))
                sign=1;
            else
                sign=-1;
            end
        elseif sec(2)==2
            refvec=[1 0 0];
            if atan2(norm(cross(refvec,-1*v1)),dot(refvec,-1*v1)) >= atan2(norm(cross(refvec,v2)),dot(refvec,v2))
                sign=1;
            else
                sign=-1;
            end
        end
end



angle=sign*rad2deg(atan2(norm(cross(v1,v2)),dot(v1,v2)));
       

else
  angle=NaN;
end

















end