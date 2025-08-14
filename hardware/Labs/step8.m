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
ADDR_PROFILE_VELOCITY     = 112;

%% ---- Configuration ---- %%
PROTOCOL_VERSION    = 2.0;
DXL_ID              = 11;
BAUDRATE            = 1000000;
DEVICENAME          = 'COM3';

TORQUE_ENABLE       = 1;
TORQUE_DISABLE      = 0;

goal_pos = [0, 2048];              % 0° ↔ 180°
PROFILE_VELOCITY = 100;
num_cycles = 2;
threshold = 20;  % encoder 误差阈值

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

%% ---- Set Operating Mode ---- %%
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_OPERATING_MODE, 3);
fprintf("Operating mode: Position Control\n");

%% ---- Set Profile Velocity ---- %%
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_PROFILE_VELOCITY, PROFILE_VELOCITY);
fprintf("Profile velocity set to %d\n", PROFILE_VELOCITY);

%% ---- Enable Torque ---- %%
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_TORQUE_ENABLE, TORQUE_ENABLE);
fprintf("Torque enabled\n");

%% ---- Move between positions using encoder feedback ---- %%
for k = 1:num_cycles
    for i = 1:2
        target = goal_pos(i);
        write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_GOAL_POSITION, target);
        fprintf("Command sent: Goal → %d\n", target);
        
        while true
            pos_raw = read4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_PRESENT_POSITION);
            pos_signed = typecast(uint32(pos_raw), 'int32');
            diff = abs(pos_signed - target);
            fprintf("Cycle %d, Target %d → Current: %d → Δ=%d\n", k, target, pos_signed, diff);
            
            if diff < threshold
                fprintf("✓ Reached target within threshold\n");
                break;
            end
            
            pause(0.05);  % 小间隔防卡死
        end
    end
end

%% ---- Disable Torque ---- %%
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
fprintf("Torque disabled\n");

%% ---- Clean Up ---- %%
closePort(port_num);
unloadlibrary(lib_name);
fprintf("Port closed and library unloaded\n");
