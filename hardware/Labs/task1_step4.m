clc;
clear all;

% --------- Dynamixel SDK Library Name --------- %
lib_name = '';
if strcmp(computer, 'PCWIN')
  lib_name = 'dxl_x86_c';
elseif strcmp(computer, 'PCWIN64')
  lib_name = 'dxl_x64_c';
elseif strcmp(computer, 'GLNX86')
  lib_name = 'libdxl_x86_c';
elseif strcmp(computer, 'GLNXA64')
  lib_name = 'libdxl_x64_c';
elseif strcmp(computer, 'MACI64')
  lib_name = 'libdxl_mac_c';
end

% --------- Load Libraries --------- %
if ~libisloaded(lib_name)
    loadlibrary(lib_name, 'dynamixel_sdk.h', ...
        'addheader', 'port_handler.h', 'addheader', 'packet_handler.h');
end

% --------- Control Table Addresses --------- %
ADDR_TORQUE_ENABLE    = 64;
ADDR_GOAL_POSITION    = 116;
ADDR_PROFILE_VELOCITY = 112;
ADDR_MAX_POS          = 48;
ADDR_MIN_POS          = 52;

% --------- Configuration --------- %
PROTOCOL_VERSION      = 2.0;
DXL_ID1               = 11;
DXL_ID2               = 12;
BAUDRATE              = 1000000;
DEVICENAME            = 'COM3';
TORQUE_ENABLE         = 1;
TORQUE_DISABLE        = 0;
MAX_POS               = 3100;
MIN_POS               = 1000;
PROFILE_VELOCITY      = 100;  % You can increase if too slow

% --------- Initialize Port --------- %
port_num = portHandler(DEVICENAME);
packetHandler();

if ~openPort(port_num)
    unloadlibrary(lib_name);
    error('❌ Failed to open port');
end
fprintf('✅ Port opened\n');

if ~setBaudRate(port_num, BAUDRATE)
    closePort(port_num);
    unloadlibrary(lib_name);
    error('❌ Failed to set baudrate');
end
fprintf('✅ Baudrate set\n');

% --------- Set Motion Limits (Torque OFF) --------- %
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_TORQUE_ENABLE, 0);
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_TORQUE_ENABLE, 0);

write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_MAX_POS, MAX_POS);
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_MIN_POS, MIN_POS);
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_MAX_POS, MAX_POS);
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_MIN_POS, MIN_POS);

write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_PROFILE_VELOCITY, PROFILE_VELOCITY);
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_PROFILE_VELOCITY, PROFILE_VELOCITY);
fprintf('✅ Motion limits and velocity set\n');

% --------- Enable Torque --------- %
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_TORQUE_ENABLE, TORQUE_ENABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_TORQUE_ENABLE, TORQUE_ENABLE);
fprintf('✅ Torque enabled on both motors\n');

% --------- STEP 4: Move Separately --------- %
positions1 = [1500, 1800, 2200];
positions2 = [2500, 2000, 1600];

for i = 1:length(positions1)
    p1 = positions1(i);
    p2 = positions2(i);

    % Move motor 1 first
    write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_GOAL_POSITION, p1);
    fprintf('➡️  Moved Motor 1 to %d\n', p1);
    pause(1);

    % Then move motor 2
    write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_GOAL_POSITION, p2);
    fprintf('➡️  Moved Motor 2 to %d\n', p2);
    pause(1);
end

% --------- Disable Torque --------- %
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
fprintf('🛑 Torque disabled\n');

% --------- Clean Up --------- %
closePort(port_num);
unloadlibrary(lib_name);
fprintf('✅ Port closed and library unloaded\n');
