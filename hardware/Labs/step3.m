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
PROFILE_VELOCITY = 50;  
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
fprintf('✅ Baudrate set to %d\n', BAUDRATE);

% --------- STEP 2: Set Motion Limits (Torque must be off) --------- %
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_TORQUE_ENABLE, 0);
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_TORQUE_ENABLE, 0);

write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_MAX_POS, MAX_POS);
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_MIN_POS, MIN_POS);
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_MAX_POS, MAX_POS);
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_MIN_POS, MIN_POS);

fprintf('✅ Motion limits set: [%d – %d]\n', MIN_POS, MAX_POS);

% --------- Set Profile Velocity --------- %
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_PROFILE_VELOCITY, PROFILE_VELOCITY);
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_PROFILE_VELOCITY, PROFILE_VELOCITY);
fprintf('Profile velocity set to %d on both motors\n', PROFILE_VELOCITY);

% --------- Enable Torque --------- %
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_TORQUE_ENABLE, TORQUE_ENABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_TORQUE_ENABLE, TORQUE_ENABLE);
fprintf('✅ Torque enabled on both motors\n');

% --------- STEP 3: Send Position Commands Simultaneously --------- %
positions = [1500, 2500, 2000];  % Three target positions within safe range

for i = 1:length(positions)
    pos = positions(i);

    write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_GOAL_POSITION, pos);
    write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_GOAL_POSITION, pos);

    fprintf('➡️  Sent position %d to both motors\n', pos);
    pause(1);  % Wait for movement to finish
end

% --------- Disable Torque --------- %
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
fprintf('🛑 Torque disabled\n');

% --------- Clean Up --------- %
closePort(port_num);
unloadlibrary(lib_name);
fprintf('✅ Port closed and library unloaded\n');
