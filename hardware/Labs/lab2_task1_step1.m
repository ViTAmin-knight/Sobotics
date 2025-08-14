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
ADDR_TORQUE_ENABLE       = 64;
ADDR_GOAL_POSITION       = 116;
ADDR_PRESENT_POSITION    = 132;
ADDR_OPERATING_MODE      = 11;
ADDR_MAX_POS             = 48;
ADDR_MIN_POS             = 52;

% --------- Configuration --------- %
PROTOCOL_VERSION         = 2.0;
DXL_ID1                  = 13;
DXL_ID2                  = 14;
BAUDRATE                 = 1000000;
DEVICENAME               = 'COM3';
TORQUE_DISABLE           = 0;

MAX_POS                  = 3100;
MIN_POS                  = 1000;

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

% --------- STEP 2: Set Motion Limits --------- %
% 关闭扭矩
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);

% 设置最大位置
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_MAX_POS, MAX_POS);
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_MAX_POS, MAX_POS);

% 设置最小位置
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_MIN_POS, MIN_POS);
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_MIN_POS, MIN_POS);

fprintf('✅ Motion limits set: [%d – %d]\n', MIN_POS, MAX_POS);

% --------- Set Both Motors to Position Control Mode --------- %
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_OPERATING_MODE, 3);
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_OPERATING_MODE, 3);
fprintf('✅ Operating mode set to Position Control\n');

% --------- Read Position While Torque is OFF (STEP 1) --------- %
fprintf('⚠️  Torque is OFF. Move joints by hand to observe position:\n');

for j = 1:100  % ≈ 10 seconds at 0.1s interval
    pos1_raw = read4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_PRESENT_POSITION);
    pos2_raw = read4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_PRESENT_POSITION);

    pos1 = typecast(uint32(pos1_raw), 'int32');
    pos2 = typecast(uint32(pos2_raw), 'int32');

    fprintf('[ID:%02d] Position: %5d\t[ID:%02d] Position: %5d\n', ...
        DXL_ID1, pos1, DXL_ID2, pos2);
    pause(0.1);
end

% --------- Clean Up --------- %
closePort(port_num);
unloadlibrary(lib_name);
fprintf('✅ Port closed and library unloaded\n');
