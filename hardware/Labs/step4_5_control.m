clc;
clear all;

%% ---- Load SDK Library ---- %%
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

if ~libisloaded(lib_name)
    loadlibrary(lib_name, 'dynamixel_sdk.h', 'addheader', 'port_handler.h', 'addheader', 'packet_handler.h');
end

%% ---- Control Table Addresses ---- %%
ADDR_TORQUE_ENABLE        = 64;
ADDR_GOAL_POSITION        = 116;
ADDR_PRESENT_POSITION     = 132;
ADDR_OPERATING_MODE       = 11;
ADDR_PROFILE_VELOCITY     = 112;   % 控制速度的地址

%% ---- Configuration ---- %%
PROTOCOL_VERSION    = 2.0;
DXL_ID              = 11;          % 舵机 ID
BAUDRATE            = 1000000;
DEVICENAME          = 'COM3';      % 串口号

TORQUE_ENABLE       = 1;
TORQUE_DISABLE      = 0;

goal_pos = [0, 2048];              % 0° ↔ 180°
PROFILE_VELOCITY = 100;             % 改这个数值控制速度（越小越慢）
num_cycles = 2;

%% ---- Initialize Port ---- %%
port_num = portHandler(DEVICENAME);
packetHandler();

if ~openPort(port_num)
    unloadlibrary(lib_name);
    error('Failed to open port');
end
fprintf("Port opened\n");

if ~setBaudRate(port_num, BAUDRATE)
    closePort(port_num);
    unloadlibrary(lib_name);
    error('Failed to set baudrate');
end
fprintf("Baudrate set\n");

%% ---- Set Operating Mode to Position Control ---- %%
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_OPERATING_MODE, 3);
fprintf("Operating mode: Position Control\n");

%% ---- Set Profile Velocity（关键速度设置） ---- %%
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_PROFILE_VELOCITY, PROFILE_VELOCITY);
fprintf("Profile velocity set to %d\n", PROFILE_VELOCITY);

%% ---- Enable Torque ---- %%
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_TORQUE_ENABLE, TORQUE_ENABLE);
fprintf("Torque enabled\n");

%% ---- Move between 0° and 180° ---- %%
for k = 1:num_cycles
    for i = 1:2
        target = goal_pos(i);
        write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_GOAL_POSITION, target);
        pause(5.0);

        % 读取当前位置
        pos_raw = read4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_PRESENT_POSITION);
        pos_signed = typecast(uint32(pos_raw), 'int32');
        fprintf("Cycle %d, Target %d → Current position: %d\n", k, target, pos_signed);
    end
end

%% ---- Disable Torque ---- %%
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
fprintf("Torque disabled\n");

%% ---- Close and Clean ---- %%
closePort(port_num);
unloadlibrary(lib_name);
fprintf("Port closed and library unloaded\n");
