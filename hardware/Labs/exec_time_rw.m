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
ADDR_PRO_PRESENT_POSITION = 132;
ADDR_PRO_GOAL_POSITION    = 116;

%% ---- Configuration ---- %%
PROTOCOL_VERSION = 2.0;
DXL_ID            = 11;
BAUDRATE          = 1000000;
DEVICENAME        = 'COM3';
goal_position     = 2048;   % dummy value for write

%% ---- Initialize Port ---- %%
port_num = portHandler(DEVICENAME);
packetHandler();

if ~openPort(port_num)
    unloadlibrary(lib_name);
    error('Failed to open port');
end
fprintf('Port opened\n');

if ~setBaudRate(port_num, BAUDRATE)
    closePort(port_num);
    unloadlibrary(lib_name);
    error('Failed to set baudrate');
end
fprintf('Baudrate set\n');

%% ---- Measure execution time ---- %%
N = 100;
read_times = zeros(N, 1);
write_times = zeros(N, 1);

fprintf("Measuring READ times...\n");
for i = 1:N
    tic;
    read4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_PRO_PRESENT_POSITION);
    read_times(i) = toc;
end

fprintf("Measuring WRITE times...\n");
for i = 1:N
    tic;
    write4ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID, ADDR_PRO_GOAL_POSITION, goal_position);
    write_times(i) = toc;
end

avg_read  = mean(read_times);
avg_write = mean(write_times);

%% ---- Frequency Calculation ---- %%
freq_1 = 1 / (avg_read + avg_write);
freq_5 = 1 / (5 * (avg_read + avg_write));

fprintf('\n Average READ time:  %.6f sec\n', avg_read);
fprintf('Average WRITE time: %.6f sec\n', avg_write);
fprintf('Estimated frequency (1 servo):  %.2f Hz\n', freq_1);
fprintf('Estimated frequency (5 servos): %.2f Hz\n', freq_5);

%% ---- Clean up ---- %%
closePort(port_num);
unloadlibrary(lib_name);
fprintf('Port closed and library unloaded\n');
