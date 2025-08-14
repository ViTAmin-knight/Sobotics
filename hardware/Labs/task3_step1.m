clc;
clear all;

% ------- Dynamixel SDK Setup ------- %
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
TORQUE_DISABLE = 0;
ENCODER_RESOLUTION = 4096;

% ------- Initialize ------- %
port_num = portHandler(DEVICENAME);
packetHandler();

if ~openPort(port_num)
    unloadlibrary(lib_name);
    error("❌ Failed to open port");
end
setBaudRate(port_num, BAUDRATE);
fprintf("✅ Port opened and baudrate set\n");

% ------- Disable torque for manual movement ------- %
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
fprintf("⚠️  Torque disabled — move joints by hand\n");

% ------- Loop: Read position and convert to angle ------- %
n_samples = 200;

for i = 1:n_samples
    % Read encoder values
    pos1_raw = read4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID1, ADDR_PRESENT_POSITION);
    pos2_raw = read4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID2, ADDR_PRESENT_POSITION);

    % Convert to signed integers
    pos1 = double(typecast(uint32(pos1_raw), 'int32'));
    pos2 = double(typecast(uint32(pos2_raw), 'int32'));

    % Convert to angle
    theta1_deg = (pos1 / ENCODER_RESOLUTION) * 360;
    theta2_deg = (pos2 / ENCODER_RESOLUTION) * 360;

    theta1_rad = theta1_deg * pi / 180;
    theta2_rad = theta2_deg * pi / 180;

    % Print
    fprintf('[%03d] Joint 13: %.2f° (%.3f rad), Joint 14: %.2f° (%.3f rad)\n', ...
        i, theta1_deg, theta1_rad, theta2_deg, theta2_rad);

    pause(0.1);
end

% ------- Close ------- %
closePort(port_num);
unloadlibrary(lib_name);
fprintf("✅ Done reading angles\n");
