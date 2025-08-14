clc;
clear all;

% ------- SDK Setup ------- %
lib_name = '';
if strcmp(computer, 'PCWIN64')
  lib_name = 'dxl_x64_c';
end
if ~libisloaded(lib_name)
    loadlibrary(lib_name, 'dynamixel_sdk.h', ...
        'addheader', 'port_handler.h', 'addheader', 'packet_handler.h');
end

% ------- Control Table Addresses ------- %
ADDR_TORQUE_ENABLE = 64;
ADDR_GOAL_POSITION = 116;
ADDR_PROFILE_VELOCITY = 112;

% ------- Configuration ------- %
PROTOCOL_VERSION = 2.0;
DXL_ID1 = 13;
DXL_ID2 = 14;
BAUDRATE = 1000000;
DEVICENAME = 'COM3';

TORQUE_ENABLE = 1;
TORQUE_DISABLE = 0;
PROFILE_VELOCITY = 100;

% ------- Initialize ------- %
port_num = portHandler(DEVICENAME);
packetHandler();
openPort(port_num);
setBaudRate(port_num, BAUDRATE);

% ------- Set velocity ------- %
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_PROFILE_VELOCITY, PROFILE_VELOCITY);
write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_PROFILE_VELOCITY, PROFILE_VELOCITY);

% ------- Enable torque ------- %
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_TORQUE_ENABLE, TORQUE_ENABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_TORQUE_ENABLE, TORQUE_ENABLE);

% ------- Generate trajectory ------- %
n_steps = 400;
t = linspace(0, 2*pi, n_steps);

% 安全中心和振幅
center1 = 2000; amp1 = 600;
center2 = 2200; amp2 = 800;

traj1 = round(center1 + amp1 * sin(t));    % ID13
traj2 = round(center2 + amp2 * cos(t));    % ID14

% ------- Trajectory tracking loop ------- %
for i = 1:n_steps
    write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_GOAL_POSITION, traj1(i));
    write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_GOAL_POSITION, traj2(i));
    pause(0.03);  % 约 33Hz
end

% ------- Disable torque ------- %
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);

% ------- Close ------- %
closePort(port_num);
unloadlibrary(lib_name);
fprintf("✅ Finished Trajectory Tracking\n");

% ------- 可视化轨迹 ------- %
figure;
plot(traj1, 'r', 'LineWidth', 1.5); hold on;
plot(traj2, 'b', 'LineWidth', 1.5);
legend('Joint 13 (sin)', 'Joint 14 (cos)');
xlabel('Step');
ylabel('Encoder Count');
title('Trajectory Tracking Inputs for Two Joints');
grid on;
axis tight;
