classdef udpobj < matlab.mixin.SetGet
    %UDPOBJ A simple object to represent the UDP connection
    %   Wraps a Java object. By no means a complete socket implementation.
    %   V.1.0 24.10.2017 Andres Agudelo-Toro
    
    properties
        RemoteHost
        RemotePort
        LocalPort
        UserData
        Status = 'closed';
        JavaAddress;
        JavaSocket
    end
    
    methods

        function obj = udpobj(remoteHost, varargin)
            % Setup parameters
            p = inputParser;
            p.addParameter('RemotePort',0,@isnumeric);
            p.addParameter('LocalPort',0,@isnumeric);
            p.parse(varargin{:});
            obj.RemoteHost = remoteHost;
            obj.RemotePort = p.Results.RemotePort;
            obj.LocalPort = p.Results.LocalPort;
        end
        
        function set.RemoteHost(obj, remotehost)
            obj.RemoteHost = remotehost;
        end
        
        function fopen(obj)
            import java.net.InetAddress
            import java.net.DatagramSocket
            
            obj.JavaAddress = InetAddress.getByName(obj.RemoteHost);
            
            % Local port could be used here but is actually ignored. The OS
            % assigns a free port
            obj.JavaSocket = DatagramSocket();            
            
            % This should allow or enable asynch sends.
            % Might have a hit on performace (?)
            obj.JavaSocket.setReuseAddress(0);
            
            % Some packets get larger than the default packet length
            % check that the size is larger than the arbitrary 768 bytes
            assert(obj.JavaSocket.getSendBufferSize() > 768);
            
            obj.Status = 'open';
        end
        
        function fwrite(obj, data)
            import java.net.DatagramPacket
            packet = DatagramPacket(data, length(data), obj.JavaAddress, obj.RemotePort);
            obj.JavaSocket.send(packet);
        end
        
        function fclose(obj)
            obj.JavaSocket.close();
            obj.Status = 'closed';
        end
    end
    
end

