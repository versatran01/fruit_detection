function [ C ] = getMousePosition()
%GETMOUSEPOSITION Get mouse position in current axes. 
C = get(gca, 'CurrentPoint');
C = C(1,1:2);
end
