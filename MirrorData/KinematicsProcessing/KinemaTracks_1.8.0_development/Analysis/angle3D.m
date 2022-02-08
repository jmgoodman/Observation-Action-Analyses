function [angle] = angle3D(vec1,vec2)

angle= acos(dot(vec1,vec2)/(norm(vec1)*norm(vec2)));  %winkel zw ab_ref & vec2