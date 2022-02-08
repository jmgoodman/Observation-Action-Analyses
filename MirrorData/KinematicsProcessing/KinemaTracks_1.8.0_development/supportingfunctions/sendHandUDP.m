function sendHandUDP(udpobj, LHO, GHO, kind, time)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                   SEND JOINT POSITIONS OVER UDP                 
%
% This function creates a string including the joints position
% acquiered with the Aurora Matlab Toolbox and sends them over UDP.
% Before the data can be sent, an UDP object has to be created [command:
% udp()] and opend [command: fopen()].
%
% sending options: 'angles'  .... sends all finger,hand and arm angles 
%                  'joints'  .... sends all finger,hand and arm joints
%                  'all'     .... sends all informations available
% 
% Helpful information: -Matlab help: " FR-FRCreating a UDP Object".
%                      -http://de.wikipedia.org/wiki/User_Datagram_Protocol
%
% Author: Stefan Schaffelhofer                                      Jan10 %
% Modified by Andres Agudelo-Toro for the realtime project    August 2015 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    global udpSendCount
    
    switch kind
        case 'Robot'
            % Send positions and angles for realtime and decoding and robot control

            % Format vectors to produce positions and
            % hand and arm angles with hand2angles
            localpos = nan(1,78);
            globalpos = nan(1,78);

            % Read global
            
            % Fingers
            nrf = size(GHO.fingerjoints,1);
            ll=1;
            for ii=1:nrf
                % GHO.fingerjoints is 5x7x7 where the first dimension is
                % finger, second is joint and third is coordinate (x,y,z)
                % hand2angles requires the MCP, PIP, DIP, Tip order
                % so array is read backwards i.e. 7=MCP, 6=PIP, 5=DIP,
                % 4=tip
                for pp=7:-1:4
                    for aa=1:3
                        globalpos(ll) = GHO.fingerjoints(ii,pp,aa);
                        ll=ll+1;
                    end
                end
            end
            
            % Reference
            globalpos(61) = GHO.reference(1,1,1);
            globalpos(62) = GHO.reference(1,1,2);
            globalpos(63) = GHO.reference(1,1,3);

            % Wrist
            globalpos(64) = GHO.armjoints(1,1);
            globalpos(65) = GHO.armjoints(1,2);
            globalpos(66) = GHO.armjoints(1,3);

            % Elbow
            globalpos(67) = GHO.armjoints(2,1);
            globalpos(68) = GHO.armjoints(2,2);
            globalpos(69) = GHO.armjoints(2,3);
         
            % Wrist help point
            globalpos(70) = GHO.armjoints(3,1);
            globalpos(71) = GHO.armjoints(3,2);
            globalpos(72) = GHO.armjoints(3,3);

            % Elbow help point
            globalpos(73) = GHO.armjoints(4,1);
            globalpos(74) = GHO.armjoints(4,2);
            globalpos(75) = GHO.armjoints(4,3);

            % Shoulder
            globalpos(76) = GHO.shoulder(1);
            globalpos(77) = GHO.shoulder(2);
            globalpos(78) = GHO.shoulder(3);
            
            % Sensors
            globalpos(79:81) = GHO.fingerjoints(1,1,1:3);
            globalpos(82:84) = GHO.fingerjoints(2,1,1:3);
            globalpos(85:87) = GHO.fingerjoints(3,1,1:3);
            globalpos(88:90) = GHO.fingerjoints(4,1,1:3);
            globalpos(91:93) = GHO.fingerjoints(5,1,1:3);

            % Read local

            % Fingers
            nrf=size(LHO.fingerjoints,1);
            ll=1;
            for ii=1:nrf
                % hand2angles requires the MCP, PIP, DIP, Tip order
                % so array is read backwards i.e. 7=MCP, 6=PIP, 5=DIP, 4=tip
                for pp=7:-1:4 
                    for aa=1:3
                        localpos(ll)= LHO.fingerjoints(ii,pp,aa);
                        ll=ll+1;
                    end
                end
            end

            % Reference
            localpos(61) = LHO.reference(1);
            localpos(62) = LHO.reference(2);
            localpos(63) = LHO.reference(3);

            % Wrist
            localpos(64) = LHO.armjoints(1,1);
            localpos(65) = LHO.armjoints(1,2);
            localpos(66) = LHO.armjoints(1,3);

            % Elbow
            localpos(67) = LHO.armjoints(2,1);
            localpos(68) = LHO.armjoints(2,2);
            localpos(69) = LHO.armjoints(2,3);

            % Wrist help point
            localpos(70) = LHO.armjoints(3,1);
            localpos(71) = LHO.armjoints(3,2);
            localpos(72) = LHO.armjoints(3,3);

            % Elbow help point
            localpos(73) = LHO.armjoints(4,1);
            localpos(74) = LHO.armjoints(4,2);
            localpos(75) = LHO.armjoints(4,3);
            
            % Shoulder
            localpos(76) = LHO.shoulder(1);
            localpos(77) = LHO.shoulder(2);
            localpos(78) = LHO.shoulder(3);
            
            % Sensors
            localpos(79:81) = LHO.fingerjoints(1,1,1:3);
            localpos(82:84) = LHO.fingerjoints(2,1,1:3);
            localpos(85:87) = LHO.fingerjoints(3,1,1:3);
            localpos(88:90) = LHO.fingerjoints(4,1,1:3);
            localpos(91:93) = LHO.fingerjoints(5,1,1:3);

            % Determine which arm is being used
            if strcmp(GHO.handside,'left')
                handside = 1;
            else
                handside = -1;
            end

            % Calculate angles in radians
            %angles = hand2angles_v3(localpos, globalpos, handside)';
            %angles = hand2angles_v4(localpos, globalpos, handside)';
            angles = hand2angles_v5(localpos, globalpos, handside)';
            
            %disp(angles)
            %disp('armjoints')
            %GHO.armjoints
            %disp('helpvector')
            %GHO.helpvector
            
            % Send positions, but convert first to musculoskeletal model
            % axes convention (X = -Xk, Y = -Zk, Z = -Yk)
            globalposm = nan(size(globalpos));
            globalposm(1:3:end) = -globalpos(1:3:end);
            globalposm(2:3:end) = -globalpos(3:3:end);
            globalposm(3:3:end) = -globalpos(2:3:end);
            
            % Send as binary
            msg = [uint8(0) ...
                typecast(swapbytes(single(time)),'uint8') ...
                typecast(swapbytes(uint32(numel(globalposm))),'uint8') ...
                typecast(swapbytes(single(globalposm)),'uint8')];
            fwrite(udpobj, msg);
            % Send as text
            %fprintf(udpobj, ['//positions//' sprintf('%%%.1f' , globalposm)]);
            
            % % TMP local pos info send
            % localposm = nan(size(localpos));
            % localposm(1:3:end) = localpos(1:3:end);
            % localposm(2:3:end) = -localpos(3:3:end);
            % localposm(3:3:end) = localpos(2:3:end);
            % fprintf(udpobj, ['//positions//' sprintf('%%%.1f' , localposm)]);
            
            % Send angles also via UDP
            
            % Send as binary
            msg = [uint8(1) ...
                typecast(swapbytes(single(time)),'uint8') ...
                typecast(swapbytes(uint32(numel(angles))),'uint8') ...
            	typecast(swapbytes(single(angles)),'uint8')];
            fwrite(udpobj, msg);
            % Send as text
            %fprintf(udpobj, ['//angles//' sprintf('%%%.4f' , angles)]);
            
            % Send finger CMC, MCP and wrist local positions every now and then. 
            % These are only changed with new calibrations and are
            % required for the proper location of the joints.           
            
            if mod(udpSendCount,1000) == 0
                l = [localpos(1:3) localpos(13:15) localpos(25:27) ...
                    localpos(37:39) localpos(49:51) localpos(64:66)];
                % Convert to musculoskeletal model
                % axes convention (X = Xk, Y = -Zk, Z = Yk)
                lm = nan(size(l));
                lm(1:3:end) = l(1:3:end);
                lm(2:3:end) = -l(3:3:end);
                lm(3:3:end) = l(2:3:end);
                % Send fixed positions via UDP
                
                % Send as binary                
                msg = [uint8(2) ...
                    typecast(swapbytes(single(time)),'uint8') ...
                    typecast(swapbytes(uint32(numel(lm))),'uint8') ...
                    typecast(swapbytes(single(lm)),'uint8')];
                fwrite(udpobj, msg);
                % Send as text
                %fprintf(udpobj, ['//fixed//' sprintf('%%%.4f' , lm)]);
            end

        case 'Local'
            % Local (old unsupported code)
            % Send positions and angles in local coordinates

            % Format vectors to produce positions and
            % hand and arm angles with hand2angles
            localpos = nan(1,78);
            globalpos = nan(1,78);

            % Read global
            
            % Fingers
            nrf = size(GHO.fingerjoints,1);
            ll=1;
            for ii=1:nrf
                % hand2angles requires the MCP, PIP, DIP, Tip order
                % so array is read backwards i.e. 7=MCP, 6=PIP, 5=DIP, 4=tip
                for pp=7:-1:4
                    for aa=1:3
                        globalpos(ll) = GHO.fingerjoints(ii,pp,aa);
                        ll=ll+1;
                    end
                end
            end
            
            % Reference
            globalpos(61) = GHO.reference(1,1,1);
            globalpos(62) = GHO.reference(1,1,2);
            globalpos(63) = GHO.reference(1,1,3);

            % Wrist
            globalpos(64) = GHO.armjoints(1,1);
            globalpos(65) = GHO.armjoints(1,2);
            globalpos(66) = GHO.armjoints(1,3);

            % Elbow
            globalpos(67) = GHO.armjoints(2,1);
            globalpos(68) = GHO.armjoints(2,2);
            globalpos(69) = GHO.armjoints(2,3);
         
            % Wrist help point
            globalpos(70) = GHO.armjoints(3,1);
            globalpos(71) = GHO.armjoints(3,2);
            globalpos(72) = GHO.armjoints(3,3);

            % Elbow help point
            globalpos(73) = GHO.armjoints(4,1);
            globalpos(74) = GHO.armjoints(4,2);
            globalpos(75) = GHO.armjoints(4,3);

            % Shoulder
            globalpos(76) = GHO.shoulder(1);
            globalpos(77) = GHO.shoulder(2);
            globalpos(78) = GHO.shoulder(3);

            % Read local

            % Fingers
            nrf=size(LHO.fingerjoints,1);
            ll=1;
            for ii=1:nrf
                % hand2angles requires the MCP, PIP, DIP, Tip order
                % so array is read backwards i.e. 7=MCP, 6=PIP, 5=DIP, 4=tip
                for pp=7:-1:4 
                    for aa=1:3
                        localpos(ll)= LHO.fingerjoints(ii,pp,aa);
                        ll=ll+1;
                    end
                end
            end

            % Reference
            localpos(61) = LHO.reference(1);
            localpos(62) = LHO.reference(2);
            localpos(63) = LHO.reference(3);

            % Wrist
            localpos(64) = LHO.armjoints(1,1);
            localpos(65) = LHO.armjoints(1,2);
            localpos(66) = LHO.armjoints(1,3);

            % Elbow
            localpos(67) = LHO.armjoints(2,1);
            localpos(68) = LHO.armjoints(2,2);
            localpos(69) = LHO.armjoints(2,3);

            % Wrist help point
            localpos(70) = LHO.armjoints(3,1);
            localpos(71) = LHO.armjoints(3,2);
            localpos(72) = LHO.armjoints(3,3);

            % Elbow help point
            localpos(73) = LHO.armjoints(4,1);
            localpos(74) = LHO.armjoints(4,2);
            localpos(75) = LHO.armjoints(4,3);
            
            % Shoulder
            localpos(76) = LHO.shoulder(1);
            localpos(77) = LHO.shoulder(2);
            localpos(78) = LHO.shoulder(3);

            % Determine which arm is being used
            if strcmp(GHO.handside,'left')
                handside = 1;
            else
                handside = -1;
            end

            % Calculate angles in radians
            %angles = hand2angles_v3(localpos, globalpos, handside);
            
            % Send positions, but convert first to musculoskeletal model
            % axes convention (X = Xk, Y = -Zk, Z = Yk)
            localposm = nan(size(localpos));
            localposm(1:3:end) = localpos(1:3:end);
            localposm(2:3:end) = -localpos(3:3:end);
            localposm(3:3:end) = localpos(2:3:end);
            fprintf(udpobj, ['//positions//' sprintf('%%%.1f' , localposm)]);

            % Send angles also via UDP
            fprintf(udpobj, ['//angles//' sprintf('%%%.4f' , angles)]);
            
            % Send finger CMC, MCP and wrist local positions every 10 seconds. 
            % These are only changed with new calibrations and are
            % required for the proper location of the joints.
            c = clock();
            if mod(floor(c(6)),10) == 0
                l = [localpos(1:3) localpos(13:15) localpos(25:27) ...
                    localpos(37:39) localpos(49:51) localpos(64:66)];
                % Convert to musculoskeletal model
                % axes convention (X = Xk, Y = -Zk, Z = Yk)
                lm = nan(size(l));
                lm(1:3:end) = l(1:3:end);
                lm(2:3:end) = -l(3:3:end);
                lm(3:3:end) = l(2:3:end);
                % Send fixed positions via UDP
                fprintf(udpobj, ['//fixed//' sprintf('%%%.4f' , lm)]);
            end

        case 'Global'
            % Global (old unsupported code)

            stream=cell(1,72);


            % fingers
            nrf=size(GHO.fingerjoints,1);

            ll=1;
            for ii=1:nrf

                for pp=4:1:7 % 4=tip, 5=DIP, 6=PIP, 7=MCP

                    for aa=1:3

                        stream{1,ll}=['%' num2str(GHO.fingerjoints(ii,pp,aa),3)];  % [fg(1,5,1),fg(1,5,2),fg(1,5,3),fg(1,4,1),fg(1,4,2),fg(1,4,3),fg(2,5,1)
                        ll=ll+1;

                    end

                end

            end

            %reference
            stream{61}=['%' num2str(GHO.reference(1,1,1),3)];
            stream{62}=['%' num2str(GHO.reference(1,1,2),3)];
            stream{63}=['%' num2str(GHO.reference(1,1,3),3)];

            %wrist
            stream{64}=['%' num2str(GHO.armjoints(1,1),3)];
            stream{65}=['%' num2str(GHO.armjoints(1,2),3)];
            stream{66}=['%' num2str(GHO.armjoints(1,3),3)];

            %elbow
            stream{67}=['%' num2str(GHO.armjoints(2,1),3)];
            stream{68}=['%' num2str(GHO.armjoints(2,2),3)];
            stream{69}=['%' num2str(GHO.armjoints(2,3),3)];

            %shoulder
            stream{70}=['%' num2str(GHO.shoulder(1),3)];
            stream{71}=['%' num2str(GHO.shoulder(2),3)];
            stream{72}=['%' num2str(GHO.shoulder(3),3)];

            sendstring=['//globalhand//' stream{1,:}];
            fprintf(udpobj, sendstring);



        otherwise
            error(['Transmission mode: "' kind '" unknown.']);
    end
    
    % Count the number of calls to this function            
    if isempty(udpSendCount)
        udpSendCount = 0;
    else
        udpSendCount = udpSendCount + 1;
    end
    
end






% % % 
% % % fingerangles = get(LHO,'fingerangles');
% % % armjoints    = get(LHO,'armjoints');
% % % armangles    = get(GHO,'armangles');
% % % shoulder     = get(LHO,'shoulder');
% % % 
% % % %%%%%%%%%%%%%%%%%%  FROM JR
% % % %% check that numbers are real
% % % for i = 1:size(fingerjoints,1)
% % %     for j = 1:size(fingerjoints,2)
% % %         if ~isreal(fingerjoints(i,j))
% % %             fingerjoints(i,j) = nan;
% % %         end
% % %     end
% % % end
% % % 
% % % for i = 1:size(fingerangles,1)
% % %     for j = 1:size(fingerangles,2)
% % %         if ~isreal(fingerangles(i,j))
% % %             fingerangles(i,j) = nan;
% % %         end
% % %     end
% % % end
% % % 
% % % for i = 1:size(armjoints,1)
% % %     for j = 1:size(armjoints,2)
% % %         if ~isreal(armjoints(i,j))
% % %             armjoints(i,j) = nan;
% % %         end
% % %     end
% % % end
% % % 
% % % for i = 1:size(armangles,1)
% % %     for j = 1:size(armangles,2)
% % %         if ~isreal(armangles(i,j))
% % %             armangles(i,j) = nan;
% % %         end
% % %     end
% % % end
% % % 
% % % for i = 1:size(shoulder,1)
% % %     for j = 1:size(shoulder,2)
% % %         if ~isreal(shoulder(i,j))
% % %             shoulder(i,j) = nan;
% % %         end
% % %     end
% % % end
% % % %%%%%%%%%%%%%%%%%%  END FROM JR
% % % 
% % % stringjoints='//fingerjoints//';
% % % % SEND JOINTS
% % %     %FINGER JOINTS
% % % for ff=1:5 % for all five fingers
% % %      if ff<=size(fingerjoints,1) % if not all fingers are enabled
% % %          stringjoints= [stringjoints ...
% % %          num2str(fingerjoints(ff,7,1))  ',' num2str(fingerjoints(ff,7,2))  ',' num2str(fingerjoints(ff,7,3))   ';' ...
% % %          num2str(fingerjoints(ff,6,1))  ',' num2str(fingerjoints(ff,6,2))  ',' num2str(fingerjoints(ff,6,3))   ';' ...
% % %          num2str(fingerjoints(ff,5,1))  ',' num2str(fingerjoints(ff,5,2))  ',' num2str(fingerjoints(ff,5,3))   ';' ...
% % %          num2str(fingerjoints(ff,4,1))  ',' num2str(fingerjoints(ff,4,2))  ',' num2str(fingerjoints(ff,4,3))   '%'];
% % %      else
% % %          stringjoints= [stringjoints ...
% % %          'NaN'  ',' 'NaN'  ',' 'NaN'   ';' ...
% % %          'NaN'  ',' 'NaN'  ',' 'NaN'   ';' ...
% % %          'NaN'  ',' 'NaN'  ',' 'NaN'   ';' ...
% % %          'NaN'  ',' 'NaN'  ',' 'NaN'   '%'];
% % %      end
% % % end
% % % stringjoints=[stringjoints '/'];
% % %     %ARM JOINTS
% % % stringjoints = ['//armjoints//' stringjoints ...
% % %                 num2str(armjoints(1,1)) ',' num2str(armjoints(1,2)) ',' num2str(armjoints(1,3)) ';' ...
% % %                 num2str(armjoints(2,1)) ',' num2str(armjoints(2,2)) ',' num2str(armjoints(2,3)) ';' ...
% % %                 num2str(shoulder(1))    ',' num2str(shoulder(2))    ',' num2str(shoulder(3))    '%'];
% % % stringjoints=[stringjoints '/'];
% % % 
% % % % SEND ANGLES
% % %     % FINGER ANGLES
% % % stringangles='//fingerangles//';
% % % for ff=1:5
% % %     if ff<=size(fingerangles,1) % if not all fingers are enabled
% % %         stringangles = [ stringangles ...
% % %             num2str(fingerangles(ff,1))  ',' num2str(fingerangles(ff,2)) ',' num2str(fingerangles(ff,3)) ',' num2str(fingerangles(ff,4))  '%'];  
% % %     else
% % %         stringangles=[ stringangles ...
% % %             'NaN' ',' 'NaN' ',' 'NaN' ',' 'NaN' '%'];   
% % %     end
% % % end
% % % stringangles=[stringangles '/'];
% % % 
% % % %     ARM ANGLES
% % % stringangles = [stringangles '//armangles//' ... % '//armangles//' stringangles ... % NOT LIKE THIS :)
% % %                 num2str(armangles(1)) ',' num2str(armangles(2)) ','  num2str(armangles(3)) ',' num2str(armangles(4)) ',' num2str(armangles(5))  ','  num2str(armangles(6)) ','  num2str(armangles(7)) '%'];
% % %     
% % % stringangles=[stringangles '/'];
% % % 
% % % switch kind
% % %     case 'All'
% % %         sendstring=[stringjoints stringangles];
% % %     case 'Joints'
% % %         sendstring= stringjoints;
% % %     case 'Angles'
% % %         sendstring= stringangles;
% % %     otherwise
% % %         sendstring=[stringjoints stringangles];
% % % end
% % % % sendstring
% % % fprintf(udpobj, sendstring);
% % % 
% % % end % end of function
