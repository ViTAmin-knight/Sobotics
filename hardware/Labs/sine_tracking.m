clc;
clear all;

%% ---- SDK Library Setup ---- %%
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

%% ---- Control Table ---- %%
ADDR_TORQUE_ENABLE         = 64;
ADDR_GOAL_POSITION         = 116;
ADDR_PRESENT_POSITION      = 132;
ADDR_OPERATING_MODE        = 11;
ADDR_PROFILE_ACCELERATION  = 108;
ADDR_PROFILE_VELOCITY      = 112;

%% ---- Config ---- %%
PROTOCOL_VERSION = 2.0;
DXL_ID = 11;
DEVICENAME = 'COM3';
BAUDRATE = 1000000;

TORQUE_ENABLE = 1;
TORQUE_DISABLE = 0;

%% ---- Motion Profile ---- %%
AMPLITUDE = 1024;       % ±90 deg
OFFSET = 1024;          % Center at 90 deg
FREQ = 0.2;             % 0.2Hz = 5s per cycle
dt = 0.01;              % control update rate
T_total = 20;           % total time
PROFILE_ACCEL = 20;     % smooth start
PROFILE_VELOCITY = 300; % decent speed

%% ---- Init ---- %%
port_num = portHandler(DEVICENAME);
packetHandler();

if ~openPort(port_num)
    error('❌ Failed to open port');
end
setBaudRate(port_num, BAUDRATE);

write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_OPERATING_MODE, 3);
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_PROFILE_ACCELERATION, PROFILE_ACCEL);
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_PROFILE_VELOCITY, PROFILE_VELOCITY);
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_TORQUE_ENABLE, TORQUE_ENABLE);
fprintf("✅ Init complete. Begin sine tracking...\n");

%% ---- Run Sine Loop ---- %%
time_log = [];
pos_log = [];
ref_log = [];

t_start = tic;
while true
    t_now = toc(t_start);
    if t_now > T_total
        break;
    end

    % Generate sine reference
    target = round(AMPLITUDE * sin(2*pi*FREQ*t_now) + OFFSET);
    write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_GOAL_POSITION, target);

    % Read current position
    pos_raw = read4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_PRESENT_POSITION);
    pos_signed = typecast(uint32(pos_raw), 'int32');

    % Log
    time_log(end+1) = t_now;
    pos_log(end+1) = pos_signed;
    ref_log(end+1) = target;

    pause(dt);
end

%% ---- Shutdown ---- %%
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
closePort(port_num);
unloadlibrary(lib_name);
fprintf("✅ Sine tracking finished\n");

%% ---- Plot ---- %%
figure;
plot(time_log, ref_log, 'r--', 'LineWidth', 1.5); hold on;
plot(time_log, pos_log, 'b', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Position (encoder)');
title('Sine Wave Tracking (0–180°)');
legend('Reference', 'Measured');
grid on;
saveas(gcf, 'sine_tracking.png');
fprintf("🖼️ Plot saved to sine_tracking.png\n");
