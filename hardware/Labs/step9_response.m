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
    loadlibrary(lib_name, 'dynamixel_sdk.h', ...
        'addheader', 'port_handler.h', ...
        'addheader', 'packet_handler.h');
end

%% ---- Control Table Addresses ---- %%
ADDR_TORQUE_ENABLE         = 64;
ADDR_GOAL_POSITION         = 116;
ADDR_PRESENT_POSITION      = 132;
ADDR_OPERATING_MODE        = 11;
ADDR_PROFILE_ACCELERATION  = 108;
ADDR_PROFILE_VELOCITY      = 112;

%% ---- Configuration ---- %%
PROTOCOL_VERSION    = 2.0;
DXL_ID              = 11;
BAUDRATE            = 1000000;
DEVICENAME          = 'COM3';

TORQUE_ENABLE       = 1;
TORQUE_DISABLE      = 0;

start_pos           = 0;       % 初始位置（0°）
goal_pos            = 2048;    % 目标位置（180°）
PROFILE_VELOCITY    = 0;       % 最大速度
PROFILE_ACCELERATION = 20;     % 推荐加速度
threshold           = 20;

%% ---- Initialize Port ---- %%
port_num = portHandler(DEVICENAME);
packetHandler();

if ~openPort(port_num)
    unloadlibrary(lib_name);
    error('❌ Failed to open port');
end
setBaudRate(port_num, BAUDRATE);
fprintf("✅ Port opened and baudrate set\n");

%% ---- Set Operating Mode ---- %%
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_OPERATING_MODE, 3);
fprintf("✅ Operating mode set to Position Control\n");

%% ---- Set Acceleration and Max Velocity ---- %%
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_PROFILE_ACCELERATION, PROFILE_ACCELERATION);
fprintf("✅ Acceleration set to %d\n", PROFILE_ACCELERATION);

write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_PROFILE_VELOCITY, PROFILE_VELOCITY);
fprintf("✅ Velocity set to MAX (0)\n");

%% ---- Enable Torque ---- %%
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_TORQUE_ENABLE, TORQUE_ENABLE);
fprintf("✅ Torque enabled\n");

%% ---- Move to Initial Position 0 ---- %%
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_GOAL_POSITION, start_pos);
fprintf("↪️ Moving to initial position 0...\n");

while true
    pos_raw = read4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_PRESENT_POSITION);
    pos_signed = typecast(uint32(pos_raw), 'int32');
    if abs(pos_signed - start_pos) < threshold
        break;
    end
    pause(0.01);
end
fprintf("✅ Reached position 0, start recording...\n");

%% ---- Send Step Command to 2048 and record response ---- %%
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_GOAL_POSITION, goal_pos);
fprintf("🚀 Sent command to move to %d\n", goal_pos);

time_log = [];
pos_log = [];

t_start = tic;
while true
    t_now = toc(t_start);
    pos_raw = read4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_PRESENT_POSITION);
    pos_signed = typecast(uint32(pos_raw), 'int32');

    time_log(end+1) = t_now;
    pos_log(end+1) = pos_signed;

    if abs(pos_signed - goal_pos) < threshold
        break;
    end
    pause(0.01);  % 10ms 采样周期
end

fprintf("✅ Reached target. Logging complete.\n");

%% ---- Disable Torque ---- %%
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
fprintf("✅ Torque disabled\n");

%% ---- Close & Unload ---- %%
closePort(port_num);
unloadlibrary(lib_name);
fprintf("✅ Port closed and library unloaded\n");

%% ---- Plot and Save Graph ---- %%
figure;
plot(time_log, pos_log, '-o');
xlabel('Time (s)');
ylabel('Position (encoder value)');
title('Step Response: 0 → 2048 at Max Speed');
grid on;
saveas(gcf, 'step9_response_plot.png');
fprintf("🖼️  Plot saved to step9_response_plot.png\n");
