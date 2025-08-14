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
ADDR_TORQUE_ENABLE     = 64;
ADDR_GOAL_POSITION     = 116;
ADDR_PRESENT_POSITION  = 132;
ADDR_PROFILE_VELOCITY  = 112;

% ------- Configuration ------- %
PROTOCOL_VERSION = 2.0;
DXL_ID1 = 13;
DXL_ID2 = 14;
BAUDRATE = 1000000;
DEVICENAME = 'COM3';

TORQUE_ENABLE  = 1;
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

% ------- Generate sine trajectory ------- %
n_steps = 400;
t = linspace(0, 2*pi, n_steps);
amp = 500;
center = 2048;
sine_traj = round(center + amp * sin(t));  % Same for both motors

% ------- Arrays to record feedback ------- %
actual_pos1 = zeros(1, n_steps);  % Feedback from Joint 13
actual_pos2 = zeros(1, n_steps);  % Feedback from Joint 14

% ------- Trajectory tracking loop ------- %
for i = 1:n_steps
    pos = sine_traj(i);

    % Send goal positions
    write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_GOAL_POSITION, pos);
    write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_GOAL_POSITION, pos);

    % Read actual positions
    raw1 = read4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_PRESENT_POSITION);
    raw2 = read4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_PRESENT_POSITION);
    actual_pos1(i) = typecast(uint32(raw1), 'int32');
    actual_pos2(i) = typecast(uint32(raw2), 'int32');

    pause(0.03);  % ~33Hz
end

% ------- Disable torque ------- %
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);

% ------- Close ------- %
closePort(port_num);
unloadlibrary(lib_name);
fprintf("✅ Finished trajectory with feedback recording\n");

% ------- Plotting: Target vs Actual ------- %
figure;
plot(sine_traj, 'k--', 'LineWidth', 1.5); hold on;
plot(actual_pos1, 'r', 'LineWidth', 1.2);
plot(actual_pos2, 'b', 'LineWidth', 1.2);
legend('Target (Sine)', 'Actual Joint 13', 'Actual Joint 14');
xlabel('Step'); ylabel('Encoder Count');
title('Target vs Actual Trajectory (Both Joints Same Sine)');
grid on;
