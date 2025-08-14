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
ADDR_TORQUE_ENABLE    = 64;
ADDR_PRESENT_POSITION = 132;
PROTOCOL_VERSION = 2.0;
DXL_ID1 = 12;   % Link 1
DXL_ID2 = 13;   % Link 2
BAUDRATE = 1000000;
DEVICENAME = 'COM3';
ENCODER_RESOLUTION = 4096;
TORQUE_DISABLE = 0;

% ------- Link Lengths (in meters) ------- %
L1 = 0.13;
L2 = 0.124;

% ------- Initialize Port ------- %
port_num = portHandler(DEVICENAME);
packetHandler();
openPort(port_num);
setBaudRate(port_num, BAUDRATE);

% ------- Disable Torque (free move mode) ------- %
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
fprintf("⚠️  Torque disabled — please move joints by hand\n");

% ------- Realtime Plot Setup ------- %
figure;
h_plot = plot(0, 0, 'b.-', 'LineWidth', 1.5); hold on;
xlabel('X Position (m)');
ylabel('Y Position (m)');
title('🟦 Real-time Tool Trajectory (Try to Draw a Square)');
axis equal;
xlim([-0.2 0.2]);
ylim([-0.2 0.2]);
grid on;

% ------- Trajectory Variables ------- %
n_steps = 300;
x_tool = zeros(1, n_steps);
y_tool = zeros(1, n_steps);

% ------- Start Real-Time Loop ------- %
for i = 1:n_steps
    % Read positions
    pos1 = double(typecast(uint32(read4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_PRESENT_POSITION)), 'int32'));
    pos2 = double(typecast(uint32(read4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_PRESENT_POSITION)), 'int32'));

    % Convert to angle
    theta1 = - (pos1 / ENCODER_RESOLUTION) * 2 * pi;
    theta2 = - (pos2 / ENCODER_RESOLUTION) * 2 * pi;

    % Forward Kinematics
    T1 = [cos(theta1), -sin(theta1), L1 * cos(theta1);
          sin(theta1),  cos(theta1), L1 * sin(theta1);
          0, 0, 1];
    T2 = [cos(theta2), -sin(theta2), L2 * cos(theta2);
          sin(theta2),  cos(theta2), L2 * sin(theta2);
          0, 0, 1];
    T_tool = T1 * T2;

    % Store coordinates
    x_tool(i) = T_tool(1,3);
    y_tool(i) = T_tool(2,3);

    % Update plot
    set(h_plot, 'XData', x_tool(1:i), 'YData', y_tool(1:i));
    drawnow;

    % Print status
    fprintf('[%03d] θ1=%.2f°, θ2=%.2f° | Tool: X=%.3f m, Y=%.3f m\n', ...
        i, rad2deg(theta1), rad2deg(theta2), x_tool(i), y_tool(i));

    pause(0.1);  % 控制刷新频率
end

% ------- Save Data ------- %
save('trajectory_live.mat', 'x_tool', 'y_tool');
csvwrite('trajectory_live.csv', [x_tool(:), y_tool(:)]);
fprintf("✅ Trajectory saved to .mat and .csv\n");

% ------- Close ------- %
closePort(port_num);
unloadlibrary(lib_name);
fprintf("✅ Port closed and library unloaded\n");
