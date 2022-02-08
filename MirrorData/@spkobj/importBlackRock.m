function [NEV] = import(spkobj,format,filename)

switch format
    case 'Blackrock'
        [fpath,fname, fext] = fileparts(filename);
        fname = [fname fext];
        fpath = [fpath '/'];
        %error check!
        


%% Reading BasicHeader information from file
FID                       = fopen([fpath fname], 'r', 'ieee-le');
BasicHeader               = fread(FID, 336, '*uint8');
NEV.MetaTags.FileTypeID   = char(BasicHeader(1:8)');
NEV.MetaTags.Flags        = dec2bin(typecast(BasicHeader(11:12), 'uint16'),16);
fExtendedHeader           = double(typecast(BasicHeader(13:16), 'uint32'));
PacketBytes               = double(typecast(BasicHeader(17:20), 'uint32'));
TimeRes                   = double(typecast(BasicHeader(21:24), 'uint32'));
NEV.MetaTags.SampleRes    = typecast(BasicHeader(25:28), 'uint32');
t                         = typecast(BasicHeader(29:44), 'uint16');
NEV.MetaTags.Comment      = char(BasicHeader(77:332)');
ExtHeaderCount            = typecast(BasicHeader(333:336), 'uint32');
if strcmpi(NEV.MetaTags.FileTypeID, 'NEURALEV')
    disp('Filespec: 2.2.')
%    METATAGS = textread([fpath fname(1:end-8) '.sif'], '%s');
%    NEV.MetaTags.Subject      = METATAGS{3}(5:end-5);
%    NEV.MetaTags.Experimenter = [METATAGS{5}(8:end-8) ' ' METATAGS{6}(7:end-7)];
else
    disp('Filespec: 2.1.');
end

%% Reading ExtendedHeader information
for ii=1:ExtHeaderCount
    ExtendedHeader = fread(FID, 32, '*uint8');
    PacketID = char(ExtendedHeader(1:8)');
    switch PacketID
        case 'ARRAYNME'
            NEV.ArrayInfo.ElectrodeName    = char(ExtendedHeader(9:end));
        case 'ECOMMENT'
            NEV.ArrayInfo.ArrayComment     = char(ExtendedHeader(9:end));
        case 'CCOMMENT'
            NEV.ArrayInfo.ArrayCommentCont = char(ExtendedHeader(9:end));
        case 'MAPFILE'
            NEV.ArrayInfo.MapFile          = char(ExtendedHeader(9:end));
        case 'NEUEVWAV'
            PacketID                       = typecast(ExtendedHeader(9:10), 'uint16');
            NEV.ElectrodesInfo{PacketID, 1}.ElectrodeID     = PacketID;
            NEV.ElectrodesInfo{PacketID, 1}.ConnectorBank   = char(ExtendedHeader(11)+64);
            NEV.ElectrodesInfo{PacketID, 1}.ConnectorPin    = ExtendedHeader(12);
            NEV.ElectrodesInfo{PacketID, 1}.DigitalFactor   = typecast(ExtendedHeader(13:14),'uint16');
            NEV.ElectrodesInfo{PacketID, 1}.EnergyThreshold = typecast(ExtendedHeader(15:16),'uint16');
            NEV.ElectrodesInfo{PacketID, 1}.HighThreshold   = typecast(ExtendedHeader(17:18),'int16');
            NEV.ElectrodesInfo{PacketID, 1}.LowThreshold    = typecast(ExtendedHeader(19:20),'int16');
            NEV.ElectrodesInfo{PacketID, 1}.Units           = ExtendedHeader(21);
            NEV.ElectrodesInfo{PacketID, 1}.WaveformBytes   = ExtendedHeader(22);
        case 'NEUEVLBL'
            PacketID                       = typecast(ExtendedHeader(9:10), 'uint16');
            NEV.ElectrodesInfo{PacketID, 1}.ElectrodeLabel = char(ExtendedHeader(11:26));
        case 'NEUEVFLT'
            PacketID                       = typecast(ExtendedHeader(9:10), 'uint16');
            NEV.ElectrodesInfo{PacketID, 1}.HighFreqCorner = typecast(ExtendedHeader(11:14),'uint32');
            NEV.ElectrodesInfo{PacketID, 1}.HighFreqOrder  = typecast(ExtendedHeader(15:18),'uint32');
            NEV.ElectrodesInfo{PacketID, 1}.HighFilterType = typecast(ExtendedHeader(19:20),'uint16');
            NEV.ElectrodesInfo{PacketID, 1}.LowFreqCorner  = typecast(ExtendedHeader(21:24),'uint32');
            NEV.ElectrodesInfo{PacketID, 1}.LowFreqOrder   = typecast(ExtendedHeader(25:28),'uint32');
            NEV.ElectrodesInfo{PacketID, 1}.LowFilterType  = typecast(ExtendedHeader(29:30),'uint16');
        case 'DIGLABEL'
            Label                                 = char(ExtendedHeader(9:24));
            Mode                                  = ExtendedHeader(25);
            NEV.IOLabels{Mode+1, 1} = Label;
        case 'NSASEXEV' %% Not implemented in the Cerebus firmware. 
                        %% Needs to be updated once implemented into the 
                        %% firmware by Blackrock Microsystems.
            NEV.NSAS.Freq          = typecast(ExtendedHeader(9:10),'uint16');
            NEV.NSAS.DigInputConf  = char(ExtendedHeader(11));
            NEV.NSAS.AnalCh1Conf   = char(ExtendedHeader(12));
            NEV.NSAS.AnalCh1Detect = typecast(ExtendedHeader(13:14),'uint16');
            NEV.NSAS.AnalCh2Conf   = char(ExtendedHeader(15));
            NEV.NSAS.AnalCh2Detect = typecast(ExtendedHeader(16:17),'uint16');
            NEV.NSAS.AnalCh3Conf   = char(ExtendedHeader(18));
            NEV.NSAS.AnalCh3Detect = typecast(ExtendedHeader(19:20),'uint16');
            NEV.NSAS.AnalCh4Conf   = char(ExtendedHeader(21));
            NEV.NSAS.AnalCh4Detect = typecast(ExtendedHeader(22:23),'uint16');
            NEV.NSAS.AnalCh5Conf   = char(ExtendedHeader(24));
            NEV.NSAS.AnalCh5Detect = typecast(ExtendedHeader(25:26),'uint16');
        otherwise
            display(['PacketID ' PacketID ' is invalid.']);
            clear variables;;
            return;
    end
end


%% Recording after ExtendedHeader file position and calculating Data Length
%  and number of data packets
fseek(FID, 0, 'eof');
fData = ftell(FID);
DataPacketCount = (fData - fExtendedHeader)/PacketBytes;
DataLen = PacketBytes - 8; %#ok<NASGU>


%%
fseek(FID, fExtendedHeader, 'bof');
Timestamps        = fread(FID, DataPacketCount, '*uint32', PacketBytes-4);
fseek(FID, fExtendedHeader+4, 'bof');
PacketIDs         = fread(FID, DataPacketCount, '*uint16', PacketBytes-2);
fseek(FID, fExtendedHeader+6, 'bof');
tempClassOrReason = fread(FID, DataPacketCount, '*uchar', PacketBytes-1);
fseek(FID, fExtendedHeader+8, 'bof');
tempDigiVals      = fread(FID, DataPacketCount, '*uint16', PacketBytes-2);
fseek(FID, fExtendedHeader+10, 'bof');
% tempThreshValues is not used because it has not been implemented in the
% firmware by Blackrock Microsystems.
tempThreshValues  = fread(FID, [5 DataPacketCount], '5*int16', PacketBytes-10); %#ok<NASGU>
fseek(FID, fExtendedHeader+8, 'bof');

%% Parse read digital data. Please refer to help to learn about the proper
% formatting if the data.
nonNeuralIndices  = find(PacketIDs == 0);
neuralIndices     = find(PacketIDs ~= 0);
nonNeuTimestamps  = Timestamps(nonNeuralIndices);
NeuTimestamps     = Timestamps(neuralIndices);
ElecNums          = PacketIDs(neuralIndices);
UnitNums          = tempClassOrReason(neuralIndices);

if 1
    DigiValues        = char(tempDigiVals(nonNeuralIndices)');
    AsteriskIndices   = find(DigiValues == '*');
    DataBegTimestamps = nonNeuTimestamps(AsteriskIndices);
    PoundIndices      = find(DigiValues == '#');
    ColonIndices      = find(DigiValues == ':');
    AfterAstAscii     = double(DigiValues(AsteriskIndices+1));
    NumAfterAstAscii  = find(AfterAstAscii >= 48 & AfterAstAscii <= 57);
    CharAfterAstAscii = find(AfterAstAscii >= 58);
    MarkerBegIndices  = AsteriskIndices(NumAfterAstAscii)+1;
    MarkerEndIndices  = PoundIndices(NumAfterAstAscii)-1;
    ParamsBegIndices  = AsteriskIndices(CharAfterAstAscii)+1;
    ParamsEndIndices  = PoundIndices(CharAfterAstAscii)-1;

    InsertionReason   = tempClassOrReason(find(PacketIDs == 0));
    Inputs = {'Digital'; 'AnCh1'; 'AnCh2'; 'AnCh3'; 'AnCh4'; 'AnCh5'; 'PerSamp'; 'Serial'};

    for i = 1:length(MarkerBegIndices)
        NEV.Data.SerialDigitalIO(NumAfterAstAscii(i)).Value(1,:) = DigiValues(MarkerBegIndices(i):MarkerEndIndices(i));
        NEV.Data.SerialDigitalIO(NumAfterAstAscii(i)).Type(1,:) = 'Marker';
    end
    for i = 1:length(ParamsBegIndices)-1
        Param        = DigiValues(ParamsBegIndices(i):ParamsEndIndices(i));
        NEV.Data.SerialDigitalIO(CharAfterAstAscii(i)).Value(1,:) = Param;
        NEV.Data.SerialDigitalIO(CharAfterAstAscii(i)).Type(1,:)  = DigiValues(ParamsBegIndices(i):ColonIndices(i)-1);
        SemiCIndices = find(NEV.Data.SerialDigitalIO(CharAfterAstAscii(i)).Value == ';');
        SemiCIndices = [find(NEV.Data.SerialDigitalIO(CharAfterAstAscii(i)).Value == ':') SemiCIndices];
        EqualIndices = find(NEV.Data.SerialDigitalIO(CharAfterAstAscii(i)).Value == '=');
        try
        for j = 1:length(EqualIndices)
            NEV.Data.SerialDigitalIO(CharAfterAstAscii(i)).(Param((SemiCIndices(j)+1):(EqualIndices(j)-1))) ...
                = str2num(Param((EqualIndices(j)+1):(SemiCIndices(j+1)-1)));
        end
        catch
            disp('There is an error in the formating of the digital data.');
            disp('Please refer to the help for more information on how to properly format the digital data for parsing.');
        end
    end
    % Populate the NEV structure with timestamps and inputtypes for the
    % digital data
%    c = num2cell(DataBegTimestamps); [NEV.Data.SerialDigitalIO(1:length(NEV.Data.SerialDigitalIO)).TimeStamp] = deal(c{1:end-1});
%    c = num2cell(DataBegTimestamps/NEV.MetaTags.SampleRes); [NEV.Data.SerialDigitalIO.TimeStampSec] = deal(c{1:end-1});
%    c = {Inputs{InsertionReason(AsteriskIndices)}}; [NEV.Data.SerialDigitalIO.InputType] = deal(c{1:end-1});
else
    NEV.Data.SerialDigitalIO.UnparsedData = tempDigiVals(nonNeuralIndices);
    NEV.Data.SerialDigitalIO.TimeStamp    = nonNeuTimestamps;
    NEV.Data.SerialDigitalIO.TimeStampSec = double(nonNeuTimestamps) / double(NEV.MetaTags.SampleRes);
end

%% Populate the NEV structure with spike timestamps, electrode numbers
% and unit numbers
NEV.Data.Spikes.Timestamps = NeuTimestamps;
NEV.Data.Spikes.Electrode  = ElecNums;
NEV.Data.Spikes.Unit       = UnitNums;


%% Format to a correct order:

%1. Suche Arrays 


        
        
    otherwise
        error('Data Type unkown.');
end




end



