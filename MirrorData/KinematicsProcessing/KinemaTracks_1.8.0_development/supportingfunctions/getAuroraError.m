function [errorMessage] = getAuroraError(aurorareturn)

error_ID=aurorareturn(findstr(aurorareturn,'ERROR')+5:findstr(aurorareturn,'ERROR')+6);

switch error_ID;
    case '01'
        errorMessage = 'Invalid command';
    case '02'
        errorMessage = 'Command too long.';
    case '03'
        errorMessage = 'Command too short.';
    case '04'
        errorMessage = 'Invalid CRC calculated for command; calculated CRC does not match the one sent.';
    case '05'
        errorMessage = 'Time-out on command execution.';
    case '06'
        errorMessage = 'Unable to set up new communication parameters. This occurs if one of the communication parameters is out of range.';
    case '07'
        errorMessage = 'Incorrect number of parameters.';
    case '08'
        errorMessage = 'Invalid port handle selected.';
    case '09'
        errorMessage = 'Invalid mode selected. Either the tool tracking priority is out of range, or the tool has sensor coils defined and "button box" was selected.';
    case '0A'
        errorMessage = 'Invalid LED selected. The LED selected is out of range.';
    case '0B'
        errorMessage = 'Invalid LED state selected. The LED selected is out of range.';
    case '0C'
        errorMessage = 'Command is invalid while in the current operating mode.';
    case '0D'
        errorMessage = 'No tool is assigned to the selected prot handle.';
    case '0E'
        errorMessage = 'Selected port handle not initialized. The port handle needs to be initialized before the command is sent.';
    case '0F'
        errorMessage = 'Selected port handle not enabled. The port handle needs to be enabled before the command is sent.';
    case '10'
        errorMessage = 'System is not initialized. The system must be initialized before the command is sent.';
    case '11'
        errorMessage = 'Unable to stop tracking. This occurs if there are hardware problems. Please contact NDI.';
    case '12'
        errorMessage = 'Unable to start tracking. This occurs if there are hardware problems. Please contact NDI.';
    case '13'
        errorMessage = 'Unable to initialize the port handle.';
    case '14'
        errorMessage = 'Invalid Field Generator characterization parameters.';
    case '15'
        errorMessage = 'Unable to initialize the system. This occurs if: (1) the system could not return to Setup mode (2) there are internal hardware problems - Please contact NDI.';
    case '16'
        errorMessage = 'Unable to start Diagnostic mode. This occurs if there are hardware problems. Please contact NDI.';
    case '17'
        errorMessage = 'Unable to stop Diagnostic mode. This occurs if there are hardware problems. Please contact NDI.';
    case '19'
        errorMessage = 'Unable to read devices firmware revision information. This occurs if: (1) the processor selected is out of range (2) the system is unable to inquire firmware revision information from a processor';
    case '1A'
        errorMessage = 'Internal system error. This occurs when the system is unable to recover after a system processing exception.';
    case '1D'
        errorMessage = 'Unable to search for SROM device IDs.';
    case '1E'
        errorMessage = 'Unable to read SROM data. This occurs if the system is: (1) unable to auto-select the first SROM device on the given port handle as a target to read from (2) unable to read a page of SROM device data successfully.';
    case '1F'
        errorMessage = 'Unable to select SROM device data. This can occur if: (1) the SROM decice starting address is out of range (2) the system is unable to auto-select the first SROM device on the given port handle as a target for writing to (3) an SROM device on the given port handle has not previously been selected with the PSEL command as a target to write to (4) the system is unable to write a page of SROM device data successfully';
    case '20'
        errorMessage = 'Unable to select SROM device for given port handle and SROM device ID.';
    case '22'
        errorMessage = 'Enabled tools are not supported by selected volume parameters.';
    case '23'
        errorMessage = 'Command parameter is out of range.';
    case '24'
        errorMessage = 'Unable to select parameters by volume. This occurs if: (1) the selected volume is not available (2) there are internal hardware errors. Please contact NDI.';
    case '25'
        errorMessage = 'Unable to determine the systems supported features list. This occurs if the system is unable to read all the hardware information.';
    case '29'
        errorMessage = 'Main processor firmware is corrupt.';  
    case '2A'
        errorMessage = 'No memory is available for dynamic allocation.';
    case '2B'
        errorMessage = 'The requested port handle has not been allocated.';
    case '2C'
        errorMessage = 'The requested port handle has become unoccupied.';
    case '2D'
        errorMessage = 'All handles have been allocated.';
    case '2E'
        errorMessage = 'Incompatible firmware versions. This can occur if: (1) a firmware update failed (2) components with incompatible firmware are connected. To correct the problem update the firmware.';
    case '31'
        errorMessage = 'Invalid input or output state.';
    case '32'
        errorMessage = 'Invalid operation for the device associated with the specified port handle.'; 
    case '33'
        errorMessage = 'Feature not available.';
    case 'F4'
        errorMessage = 'Unable to erase Flash SROM device.';
    case 'F5'
        errorMessage = 'Unable to write Flash SROM device.';
    case 'F6'
        errorMessage = 'Unable to read Flash SROM device.';
end