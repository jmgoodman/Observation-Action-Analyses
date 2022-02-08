function [id]=createpositionid(k)

id=cell(1,72);

id{1,1} =['Thumb MCP x ' k];
id{1,2} =['Thumb MCP y ' k];
id{1,3} =['Thumb MCP z ' k];

id{1,4} =['Thumb PIP x ' k];
id{1,5} =['Thumb PIP y ' k];
id{1,6} =['Thumb PIP z ' k];

id{1,7} =['Thumb DIP x ' k];
id{1,8} =['Thumb DIP y ' k];
id{1,9} =['Thumb DIP z ' k];

id{1,10}=['Thumb TIP x ' k];
id{1,11}=['Thumb TIP y ' k];
id{1,12}=['Thumb TIP z ' k];

id{1,13} =['Index MCP x ' k];
id{1,14} =['Index MCP y ' k];
id{1,15} =['Index MCP z ' k];

id{1,16} =['Index PIP x ' k];
id{1,17} =['Index PIP y ' k];
id{1,18} =['Index PIP z ' k];

id{1,19} =['Index DIP x ' k];
id{1,20} =['Index DIP y ' k];
id{1,21} =['Index DIP z ' k];

id{1,22}=['Index TIP x ' k];
id{1,23}=['Index TIP y ' k];
id{1,24}=['Index TIP z ' k];

id{1,25} =['Middle MCP x ' k];
id{1,26} =['Middle MCP y ' k];
id{1,27} =['Middle MCP z ' k];

id{1,28} =['Middle PIP x ' k];
id{1,29} =['Middle PIP y ' k];
id{1,30} =['Middle PIP z ' k];

id{1,31} =['Middle DIP x ' k];
id{1,32} =['Middle DIP y ' k];
id{1,33} =['Middle DIP z ' k];

id{1,34}=['Middle TIP x ' k];
id{1,35}=['Middle TIP y ' k];
id{1,36}=['Middle TIP z ' k];

id{1,37} =['Ring MCP x ' k];
id{1,38} =['Ring MCP y ' k];
id{1,39} =['Ring MCP z ' k];

id{1,40} =['Ring PIP x ' k];
id{1,41} =['Ring PIP y ' k];
id{1,42} =['Ring PIP z ' k];

id{1,43} =['Ring DIP x ' k];
id{1,44} =['Ring DIP y ' k];
id{1,45} =['Ring DIP z ' k];

id{1,46}=['Ring TIP x ' k];
id{1,47}=['Ring TIP y ' k];
id{1,48}=['Ring TIP z ' k];

id{1,49} =['Little MCP x ' k];
id{1,50} =['Little MCP y ' k];
id{1,51} =['Little MCP z ' k];

id{1,52} =['Little PIP x ' k];
id{1,53} =['Little PIP y ' k];
id{1,54} =['Little PIP z ' k];

id{1,55} =['Little DIP x ' k];
id{1,56} =['Little DIP y ' k];
id{1,57} =['Little DIP z ' k];

id{1,58}=['Little TIP x ' k];
id{1,59}=['Little TIP y ' k];
id{1,60}=['Little TIP z ' k];

id{1,61}=['Dorsum x ' k]; % Sensor position
id{1,62}=['Dorsum y ' k];
id{1,63}=['Dorsum z ' k];

id{1,64}=['Wrist x ' k]; % Position wrist joint
id{1,65}=['Wrist y ' k];
id{1,66}=['Wrist z ' k];

id{1,67}=['Elbow x ' k];
id{1,68}=['Elbow y ' k];
id{1,69}=['Elbow z ' k];

id{1,70}=['Help Point W1 x ' k];
id{1,71}=['Help Point W1 y ' k];
id{1,72}=['Help Point W1 z ' k];

id{1,73}=['Help Point E1 x ' k];
id{1,74}=['Help Point E1 y ' k];
id{1,75}=['Help Point E1 z ' k];

id{1,76}=['Shoulder x ' k];
id{1,77}=['Shoulder y ' k];
id{1,78}=['Shoulder z ' k];

id{1,76}=['Help Point F1 x ' k];
id{1,77}=['Help Point F1 y ' k];
id{1,78}=['Help Point F1 z ' k];

id{1,76}=['Help Point F2 x ' k];
id{1,77}=['Help Point F2 y ' k];
id{1,78}=['Help Point F2 z ' k];

id{1,76}=['Help Point F3 x ' k];
id{1,77}=['Help Point F3 y ' k];
id{1,78}=['Help Point F3 z ' k];

id{1,76}=['Help Point F4 x ' k];
id{1,77}=['Help Point F4 y ' k];
id{1,78}=['Help Point F4 z ' k];

id{1,76}=['Help Point F5 x ' k];
id{1,77}=['Help Point F5 y ' k];
id{1,78}=['Help Point F5 z ' k];


end