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

% ------- Configuration ------- %
PROTOCOL_VERSION = 2.0;
DXL_ID1 = 13;
DXL_ID2 = 14;
BAUDRATE = 1000000;
DEVICENAME = 'COM3';
ENCODER_RESOLUTION = 4096;
TORQUE_DISABLE = 0;

% ------- Link lengths (in meters) ------- %
L1 = 0.13;   % Link 1
L2 = 0.124;  % Link 2

% ------- Initialize ------- %
port_num = portHandler(DEVICENAME);
packetHandler();

openPort(port_num);
setBaudRate(port_num, BAUDRATE);

% ------- Disable torque for manual testing ------- %
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
fprintf("⚠️  Torque disabled — move joints by hand\n");

% ------- Loop: Read, compute T1/T2, and print X/Y ------- %
n_steps = 100;
for i = 1:n_steps
    % --- Read angles ---
    pos1_raw = read4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_PRESENT_POSITION);
    pos2_raw = read4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_PRESENT_POSITION);
    theta1_deg = double(typecast(uint32(pos1_raw), 'int32')) / ENCODER_RESOLUTION * 360;
    theta2_deg = double(typecast(uint32(pos2_raw), 'int32')) / ENCODER_RESOLUTION * 360;
    theta1 = theta1_deg * pi / 180;
    theta2 = theta2_deg * pi / 180;

    % --- Transformation Matrices ---
    T1 = [cos(theta1), -sin(theta1), L1 * cos(theta1);
          sin(theta1),  cos(theta1), L1 * sin(theta1);
          0, 0, 1];
    T2 = [cos(theta2), -sin(theta2), L2 * cos(theta2);
          sin(theta2),  cos(theta2), L2 * sin(theta2);
          0, 0, 1];
    T_tool = T1 * T2;
    x_tool = T_tool(1,3);
    y_tool = T_tool(2,3);

    % --- Print results ---
    fprintf('[%03d] θ1=%.2f°, θ2=%.2f° | Tool Position: X=%.3f m, Y=%.3f m\n', ...
        i, theta1_deg, theta2_deg, x_tool, y_tool);

    pause(0.1);
end

% ------- Clean up ------- %
closePort(port_num);
unloadlibrary(lib_name);
fprintf("✅ FK Calculation Complete\n");
