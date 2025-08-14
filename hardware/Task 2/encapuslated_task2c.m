function OpenManipulatorX_TrajectoryControl
% OpenManipulatorX_TrajectoryControl
% -------------------------------------------------------------------------
% Demonstrates how to encapsulate two functions:
%   planJointSpaceTrajectory   - Perform quintic polynomial interpolation in joint space
%   planCartesianSpaceTrajectory - Perform quintic polynomial interpolation in Cartesian space followed by inverse kinematics
%
% In the main procedure:
%   - Initialize servos, DH parameters, offsets, etc.
%   - Execute multiple joint space motions (e.g., holdQ -> initial -> ...), while retaining gripper logic.

clc; clear; close all;

%% Declare globals for use in subfunctions
global port_num PROTOCOL_VERSION dxl_lib_name DXL_ID1 DXL_ID2 DXL_ID3 DXL_ID4 DXL_ID5 ADDR_PRO_PRESENT_POSITION
global hEndEff hTrajectory globalTrajectory FK_4dof startP startQ endP endQ joint_limits

%% ========== 1) Dynamixel SDK Initialization ==========
lib_name = selectDynLibName();
dxl_lib_name = lib_name;  
if ~libisloaded(lib_name)
    [~, ~] = loadlibrary(lib_name, 'dynamixel_sdk.h', ...
        'addheader','port_handler.h', ...
        'addheader','packet_handler.h', ...
        'addheader','group_sync_read.h');
end

%% User-adjustable control addresses and parameters
global ADDR_PRO_OPERATING_MODE ADDR_PRO_TORQUE_ENABLE ...
       ADDR_PRO_GOAL_POSITION ADDR_PRO_PRESENT_POSITION ...
       ADDR_MAX_POS ADDR_MIN_POS ...
       ADDR_PROFILE_ACCELERATION ADDR_PROFILE_VELOCITY 

ADDR_PRO_OPERATING_MODE    = 11;
ADDR_PRO_TORQUE_ENABLE     = 64;
ADDR_PRO_GOAL_POSITION     = 116;
ADDR_PRO_PRESENT_POSITION  = 132;
ADDR_MAX_POS               = 48;
ADDR_MIN_POS               = 52;
ADDR_PROFILE_ACCELERATION  = 108;
ADDR_PROFILE_VELOCITY      = 112;

PROTOCOL_VERSION = 2;  

DXL_ID1 = 11;
DXL_ID2 = 12;
DXL_ID3 = 13;
DXL_ID4 = 14;
DXL_ID5 = 15;

BAUDRATE   = 1000000;
DEVICENAME = 'COM9';

TORQUE_ENABLE  = 1;
TORQUE_DISABLE = 0;

global MAX_POS MIN_POS
MAX_POS = 4095;
MIN_POS = 0;

% Open port
port_num = portHandler(DEVICENAME);
packetHandler();

if openPort(int32(port_num))
    fprintf('Port successfully opened\n');
else
    unloadlibrary(lib_name);
    error('Failed to open port. Check the port name or device connection.');
end

% Set baud rate
if setBaudRate(int32(port_num), BAUDRATE)
    fprintf('Baud rate successfully set\n');
else
    unloadlibrary(lib_name);
    error('Failed to set baud rate.');
end

write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID1), int32(ADDR_PRO_TORQUE_ENABLE), int32(0));
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID2), int32(ADDR_PRO_TORQUE_ENABLE), int32(0));
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID3), int32(ADDR_PRO_TORQUE_ENABLE), int32(0));
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID4), int32(ADDR_PRO_TORQUE_ENABLE), int32(0));
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID5), int32(ADDR_PRO_TORQUE_ENABLE), int32(0));

%% Initialize the gripper (5th axis) = current control mode (0)
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID5), int32(ADDR_PRO_TORQUE_ENABLE), int32(0));
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID5), int32(ADDR_PRO_OPERATING_MODE), int32(0));
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID5), int32(ADDR_PRO_TORQUE_ENABLE), int32(1));

%% ========== 2) Set DH Parameters, Offsets, and Joint Limits ==========
theta_offset = [
    0;
    -atan(128/24);
    +atan(128/24);
    0;
    0
];

alpha = [0, -pi/2, 0, 0, 0]; 
a     = [0, 0, 0.13, 0.124, 0.126];
d     = [0.077, 0, 0, 0, 0];

joint_limits = [
   -pi,    pi;
   -pi,    pi;
   -pi,    pi;
   -pi,    pi;
   -pi,    pi  
];

enc_min = round((-pi/(2*pi))*4096 + 2048);
enc_max = round(( pi/(2*pi))*4096 + 2048);
write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID1), int32(ADDR_MAX_POS), int32(enc_max));
write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID2), int32(ADDR_MAX_POS), int32(enc_max));
write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID3), int32(ADDR_MAX_POS), int32(enc_max));
write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID4), int32(ADDR_MAX_POS), int32(enc_max));

write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID1), int32(ADDR_MIN_POS), int32(enc_min));
write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID2), int32(ADDR_MIN_POS), int32(enc_min));
write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID3), int32(ADDR_MIN_POS), int32(enc_min));
write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID4), int32(ADDR_MIN_POS), int32(enc_min));

write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID1), int32(ADDR_PRO_OPERATING_MODE), int32(3));
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID2), int32(ADDR_PRO_OPERATING_MODE), int32(3));
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID3), int32(ADDR_PRO_OPERATING_MODE), int32(3));
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID4), int32(ADDR_PRO_OPERATING_MODE), int32(3));


FK_4dof = @(q_servo) forwardKinematics_DH(q_servo, alpha, a, d, theta_offset);

% %% ======== 2.5) Real-Time End-Effector Monitor Setup =========
% globalTrajectory = [];
% hFig = figure('Name','Real-Time End-Effector Monitor');
% axis([-0.2 0.4 -0.2 0.4 -0.5 0.5]); grid on; hold on;
% xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
% title('Real-Time End-Effector Position and Trajectory');
% view(3); rotate3d on;
% hEndEff = plot3(0,0,0,'ro','MarkerSize',10,'MarkerFaceColor','r');
% hTrajectory = plot3(nan, nan, nan, 'b-', 'LineWidth',2);

%% ========== 4) Move to Starting Region (Using Joint-Space Trajectories) ==========
disp('Enabling torque for trajectory execution...');
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID1), int32(ADDR_PRO_TORQUE_ENABLE), int32(1));
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID2), int32(ADDR_PRO_TORQUE_ENABLE), int32(1));
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID3), int32(ADDR_PRO_TORQUE_ENABLE), int32(1));
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID4), int32(ADDR_PRO_TORQUE_ENABLE), int32(1));
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID5), int32(ADDR_PRO_TORQUE_ENABLE), int32(1));

PROFILE_VELOCITY_LIMIT    = 100;
PROFILE_VELOCITY_LIMIT_5  = 1;
PROFILE_ACCELERATION_LIMIT= 100;
PROFILE_ACCELERATION_LIMIT_5 = 5;
write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID1), int32(ADDR_PROFILE_VELOCITY), int32(PROFILE_VELOCITY_LIMIT));
write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID2), int32(ADDR_PROFILE_VELOCITY), int32(PROFILE_VELOCITY_LIMIT));
write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID3), int32(ADDR_PROFILE_VELOCITY), int32(PROFILE_VELOCITY_LIMIT));
write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID4), int32(ADDR_PROFILE_VELOCITY), int32(PROFILE_VELOCITY_LIMIT));
write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID5), int32(ADDR_PROFILE_VELOCITY), int32(PROFILE_VELOCITY_LIMIT));
write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID1), int32(ADDR_PROFILE_ACCELERATION), int32(PROFILE_ACCELERATION_LIMIT));
write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID2), int32(ADDR_PROFILE_ACCELERATION), int32(PROFILE_ACCELERATION_LIMIT));
write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID3), int32(ADDR_PROFILE_ACCELERATION), int32(PROFILE_ACCELERATION_LIMIT));
write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID4), int32(ADDR_PROFILE_ACCELERATION), int32(PROFILE_ACCELERATION_LIMIT));
write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID5), int32(ADDR_PROFILE_ACCELERATION), int32(PROFILE_ACCELERATION_LIMIT_5));

%% Record coordinate area %%
initialP = [  -0.0388   -0.1317    0.2082];
initialQ = [-1.8577   -0.0828    0.0675    1.05];

pase = 0.025;
pre_pos = 0.12; %pre-grab position

intial2block1 = [4*pase 0 pre_pos+0.07];

bridge1_offset = 0.007;
bridge2_offset = 0.007;
bridge3_offset = 0.002;
bridge4_offset = 0.030;

graspP = [-2.1*pase -8*pase 0.09];

bridge2_gripper_offset =0.785 ;

bridge1_pre =[4*pase-bridge1_offset -6*pase 0.115];
bridge1middle=[4*pase-bridge1_offset -5*pase 0.115];
bridge1out=[4*pase-bridge1_offset -4*pase 0.115];

bridge2_pre =[9*pase-bridge2_offset -4*pase 0.146];
bridge2middle=[9*pase-bridge2_offset -2*pase 0.145];
bridge2out=[9*pase-bridge2_offset -1*pase 0.146];

bridge3_pre =[7*pase-bridge3_offset 1*pase 0.14];
bridge3middle=[7*pase-bridge3_offset 2*pase 0.14];
bridge3out=[7*pase-bridge3_offset 3*pase 0.14];

bridge4_pre =[5*pase 5*pase-bridge4_offset 0.115];
bridge4middle=[4*pase 5*pase-bridge4_offset 0.115];
bridge4out=[3*pase 5*pase-bridge4_offset 0.115];

% First, "hold" the current pose
holdQ = readAllJointAngles();
N_hold = 1;
q_traj_hold = repmat(holdQ, N_hold, 1)';  % 4×N_hold
disp('Holding current pose...');
sendTrajectory(q_traj_hold, port_num, PROTOCOL_VERSION, [DXL_ID1, DXL_ID2, DXL_ID3, DXL_ID4], 0.1, FK_4dof);

% % ========== At hold, Open the Gripper (position control) ==========
gripperOpen();

collectorQ = readAllJointAngles();
[collectorP,~] = forwardKinematics_DH(collectorQ, alpha, a, d, theta_offset);

% --- (0) From Initial to testinitialP ---
N_traj2 = 20; T2 = 0.1;
q_traj_start2end = planCartesianSpaceTrajectory(collectorP, intial2block1, T2, N_traj2, readAllJointAngles, FK_4dof, joint_limits, alpha, a, d, theta_offset, 0);
disp('Start sweeping across hole 3-9 (cartesian space)...');
sendTrajectory(q_traj_start2end, port_num, PROTOCOL_VERSION, [DXL_ID1, DXL_ID2, DXL_ID3, DXL_ID4], T2, FK_4dof);

graspPhigher = graspP;
graspPhigher(3) = graspPhigher(3) + 0.05;

% % --- (1) From holdQ -> graspPhigher ---
executePathSegment('startCoord', intial2block1, 'endCoord', graspPhigher, 'planType', 3, 'NPoints', 20, 'TotalTime', 0.5, 'Degree', 45);

% --- (2) From graspPhigher to graspP ---
executePathSegment('startCoord', graspPhigher, 'endCoord', graspP, 'planType', 3, 'NPoints', 10, 'TotalTime', 0.3, 'Degree', 45);

% --- Gripper closing ---
gripperClose();
pause(0.5);

% --- (3) From graspP to graspP_lifted ---
collectorQ = readAllJointAngles();
[collectorP,~] = forwardKinematics_DH(collectorQ, alpha, a, d, theta_offset);
graspP_lifted = collectorP;
graspP_lifted(3) = graspP_lifted(3) + 0.05;

executePathSegment('startCoord', graspP, 'endCoord', graspP_lifted, 'planType', 4, 'NPoints', 10, 'TotalTime', 0.3, 'Degree', 45);

% --- (4) From graspP_lifted to bridge1_pre ---
executePathSegment('startCoord', graspP_lifted, 'endCoord', bridge1_pre, 'planType', 3, 'NPoints', 10, 'TotalTime', 0.1, 'Degree', 45);

% --- (5) From bridge1_pre to bridge1out ---
% executePathSegment('startCoord', bridge1_pre, 'endCoord', bridge1middle, 'planType', 3, 'NPoints', 5, 'TotalTime', 0.1, 'Degree', 45);

executePathSegment('startCoord', bridge1_pre, 'endCoord', bridge1out, 'planType', 3, 'NPoints', 10, 'TotalTime', 0.1, 'Degree', 45);

% --- (6) From bridge1out to bridge2_pre ---
executePathSegment('startCoord', bridge1out, 'endCoord', bridge2_pre, 'planType', 3, 'NPoints', 10, 'TotalTime', 0.1, 'Degree', 45);

% --- (7) From bridge2_pre to bridge2out ---
% executePathSegment('startCoord', bridge2_pre, 'endCoord', bridge2middle, 'planType', 3, 'NPoints', 5, 'TotalTime', 0.1, 'Degree', 45);

executePathSegment('startCoord', bridge2_pre, 'endCoord', bridge2out, 'planType', 3, 'NPoints', 10, 'TotalTime', 0.1, 'Degree', 45);

% --- (8) From bridge2out to bridge3_pre ---
executePathSegment('startCoord', bridge2out, 'endCoord', bridge3_pre, 'planType', 3, 'NPoints', 10, 'TotalTime', 0.1, 'Degree', 45);

% --- (9) From bridge3_pre to bridge3_pre ---
% executePathSegment('startCoord', bridge3_pre, 'endCoord', bridge3middle, 'planType', 3, 'NPoints', 5, 'TotalTime', 0.1, 'Degree', 45);

executePathSegment('startCoord', bridge3_pre, 'endCoord', bridge3out, 'planType', 3, 'NPoints', 10, 'TotalTime', 0.1, 'Degree', 45);

% --- (10) From bridge3out to bridge4_pre ---
executePathSegment('startCoord', bridge3out, 'endCoord', bridge4_pre, 'planType', 3, 'NPoints', 10, 'TotalTime', 0.1, 'Degree', 45);

% --- (11) From bridge4_pre to bridge4out ---
% executePathSegment('startCoord', bridge4_pre, 'endCoord', bridge4middle, 'planType', 3, 'NPoints', 5, 'TotalTime', 0.1, 'Degree', 45);

executePathSegment('startCoord', bridge4_pre, 'endCoord', bridge4out, 'planType', 3, 'NPoints', 10, 'TotalTime', 0.1, 'Degree', 45);

pause(1.5);

gripperOpen();

pause(3);





% --- (7) End & Close Port ---
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID1), int32(ADDR_PRO_TORQUE_ENABLE), int32(0));
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID2), int32(ADDR_PRO_TORQUE_ENABLE), int32(0));
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID3), int32(ADDR_PRO_TORQUE_ENABLE), int32(0));
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID4), int32(ADDR_PRO_TORQUE_ENABLE), int32(0));
write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID5), int32(ADDR_PRO_TORQUE_ENABLE), int32(0));

closePort(int32(port_num));
unloadlibrary(lib_name);
close all;
end  % main function

%% all functions

function executePathSegment(varargin)
    %   startCoord    : Starting coordinate. If planType==1 or 2, it is a 1×4 joint angle vector;
    %                   if planType==3 or 4, it is a 1×3 end-effector pose [x y z]
    %   endCoord      : Ending coordinate, with the same format as startCoord
    %   planType      : Planning method: 1 = Stable, 2 = Joint Space, 3 = Cartesian Space (analytical), 4 = Cartesian Space (numerical)
    %   T_total       : Total duration 
    %   N_points      : Number of points.
    %   constraintDeg : Constraint angle (in degrees) 
    
    p = inputParser;
    addParameter(p, 'startCoord', []);  
    addParameter(p, 'endCoord', []);    
    addParameter(p, 'planType', 1);      
    addParameter(p, 'TotalTime', 1);      
    addParameter(p, 'NPoints', 50);      
    addParameter(p, 'Degree', 45);       
    parse(p, varargin{:});
    
    % Retrieve the parsed parameters
    startCoord = p.Results.startCoord;
    endCoord   = p.Results.endCoord;
    planType   = p.Results.planType;
    T_total    = p.Results.TotalTime;
    N_points   = p.Results.NPoints;
    constraintDeg = p.Results.Degree;
    
    global port_num PROTOCOL_VERSION FK_4dof joint_limits alpha a d theta_offset DXL_ID1 DXL_ID2 DXL_ID3 DXL_ID4
    
    % Plan the trajectory
    traj = struct();
    switch planType
        case 1  % Stable trajectory
            traj.data = planStableTrajectory(startCoord, N_points);
            traj.type = 'Stable';
        case 2  % Joint Space trajectory
            traj.data = planJointSpaceTrajectory(startCoord, endCoord, T_total, N_points);
            traj.type = 'Joint Space';
        case 3  % Cartesian Space trajectory
            q_init = readAllJointAngles();  
            constraintRad = constraintDeg * pi/180;  % Convert constraint angle to radians
            traj.data = planCartesianSpaceTrajectory(startCoord, endCoord, T_total, N_points, q_init, FK_4dof, joint_limits, alpha, a, d, theta_offset, constraintRad);
            traj.type = 'Cartesian Space (analytical)';
        case 4 
            q_init = readAllJointAngles();  
            constraintRad = constraintDeg * pi/180;  
            traj.data = planCartesianSpaceTrajectory_numerical(startCoord, endCoord, T_total, N_points, q_init, FK_4dof, joint_limits, alpha, a, d, theta_offset, constraintRad);
            traj.type = 'Cartesian Space (numerical)';
        otherwise
            error('Unknown plan type: %d', planType);
    end
    
    sendTrajectory(traj.data, port_num, PROTOCOL_VERSION, [DXL_ID1, DXL_ID2, DXL_ID3, DXL_ID4], T_total);

end


% Gripper Open
function gripperOpen()
    global PROTOCOL_VERSION ADDR_PRO_TORQUE_ENABLE ADDR_PRO_OPERATING_MODE ADDR_PRO_GOAL_POSITION ADDR_PROFILE_VELOCITY ADDR_PROFILE_ACCELERATION port_num DXL_ID5 PROFILE_VELOCITY_LIMIT_5 PROFILE_ACCELERATION_LIMIT_5
    write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID5), int32(ADDR_PRO_TORQUE_ENABLE), int32(0));
    write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID5), int32(ADDR_PRO_OPERATING_MODE), int32(3));
    write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID5), int32(ADDR_PRO_TORQUE_ENABLE), int32(1));
    target_pos = round((-1.57/(2*pi))*4096) + 2048;
    write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID5), int32(ADDR_PRO_GOAL_POSITION), int32(target_pos));
end

function gripperOpenSlow()
    global PROTOCOL_VERSION ADDR_PRO_TORQUE_ENABLE ADDR_PRO_OPERATING_MODE ADDR_PRO_GOAL_POSITION ADDR_PROFILE_VELOCITY ADDR_PROFILE_ACCELERATION port_num DXL_ID5 PROFILE_VELOCITY_LIMIT_5 PROFILE_ACCELERATION_LIMIT_5
    global ADDR_PRO_PRESENT_POSITION
    write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID5), int32(ADDR_PRO_TORQUE_ENABLE), int32(0));
    write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID5), int32(ADDR_PRO_OPERATING_MODE), int32(3));
    write1ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID5), int32(ADDR_PRO_TORQUE_ENABLE), int32(1));
    
    start_pos = read4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID5), int32(ADDR_PRO_PRESENT_POSITION));
    
    target_pos = round((-1.57/(2*pi))*4096) + 2048;
    
    T_total = 1.5;         
    N_points = 30;         
    t_way = [0, T_total]; 
    t_query = linspace(0, T_total, N_points);  
    
    vel_bc = [0, 0];
    acc_bc = [0, 0];
    

    pos_traj = quinticpolytraj([start_pos, target_pos], t_way, t_query, ...
        'VelocityBoundaryCondition', vel_bc, 'AccelerationBoundaryCondition', acc_bc);
    
    for i = 1:length(pos_traj)
        pos_cmd = round(pos_traj(i));
        pos_cmd = max(0, min(4095, pos_cmd)); 
        write4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID5), int32(ADDR_PRO_GOAL_POSITION), int32(pos_cmd));
        pause(T_total/N_points);
    end
    
    disp('The clamping jaws have been opened by five interpolated trajectories.');
end

% Gripper Close
function gripperClose()
    global PROTOCOL_VERSION ADDR_PRO_TORQUE_ENABLE ADDR_PRO_OPERATING_MODE port_num DXL_ID5
    write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID5, ADDR_PRO_TORQUE_ENABLE, 0);
    write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID5, ADDR_PRO_OPERATING_MODE, 0);
    write1ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID5, ADDR_PRO_TORQUE_ENABLE, 1);
    current_cmd = 30;
    current_data = typecast(int16(current_cmd), 'uint16');
    write2ByteTxRx(port_num, PROTOCOL_VERSION, DXL_ID5, 102, current_data);
    disp('Gripper closed.');
    pause(0.5);
end

%% ================================ Subfunctions ================================

function lib_name = selectDynLibName()
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
    else
        lib_name = '';
    end
end

function [p_end, T_all] = forwardKinematics_DH(q_servo, alpha, a, d, offset)
    if length(q_servo) < length(alpha)
         q_servo = [q_servo, 0];
    end
    n = length(q_servo);
    T_current = eye(4);
    T_all = cell(n+1,1);
    T_all{1} = T_current;
    for i = 1:n
        theta_i = q_servo(i) + offset(i);
        T_i = DHmatrix_Craig(alpha(i), a(i), d(i), theta_i);
        T_current = T_current * T_i;
        T_all{i+1} = T_current;
    end
    p_end = T_current(1:3,4);
end

function T = DHmatrix_Craig(alpha_prev, a_prev, d_i, theta_i)
    ct = cos(theta_i);
    st = sin(theta_i);
    ca = cos(alpha_prev);
    sa = sin(alpha_prev);
    T = [ ct, -st, 0, a_prev;
          st*ca, ct*ca, -sa, -sa*d_i;
          st*sa, ct*sa, ca, ca*d_i;
          0, 0, 0, 1 ];
end


function [q_sol, valid] = analyticalIK_withGamma(p_des, gamma, joint_limits)
    x = p_des(1);
    y = p_des(2);
    z = p_des(3);

    d1 = 0.077;  
    A  = 0.13;    
    B  = 0.124;   

    q1 = atan2(y, x);  
    x4 = x - 0.126 * cos(gamma) * cos(q1);
    y4 = y - 0.126 * cos(gamma) * sin(q1);
    z4 = z + 0.126 * sin(gamma);

    allSolutions = [];

    q1_candidates = [q1, q1 + pi];

    for q1_DH = q1_candidates
        r = hypot(x4, y4);
        z_eff = z4 - d1;

        if r > (A+B) || r < abs(A-B)
            continue;
        end

        cos_q3 = (r^2 + z_eff^2 - A^2 - B^2) / (2*A*B);
        if abs(cos_q3) > 1
            continue;
        end

        % Two elbow solutions
        q3_DH_opts = [acos(cos_q3), -acos(cos_q3)];

        for q3_DH = q3_DH_opts
            phi2 = atan2(z_eff, r);
            psi  = atan2(B*sin(q3_DH), A + B*cos(q3_DH));
            q2_DH = phi2 - psi;

            % Check for grounding
            elbow_z = d1 + A*sin(q2_DH);
            end_z   = d1 + A*sin(q2_DH) + B*sin(q2_DH + q3_DH);
            if (elbow_z < -0.1) || (end_z < -0.1)
                continue;
            end

            % ---- 4) Go to servo angle (with offset) ----
            offset_4 = [0; -atan(128/24); +atan(128/24); 0];
            q1_servo = q1_DH - offset_4(1);
            q2_servo = -q2_DH - offset_4(2);
            q3_servo = -q3_DH - offset_4(3);
            q4_servo = gamma - (q2_servo + q3_servo);

            % The fifth joint does not move
            q5_servo = 0;

            q_candidate = [q1_servo, q2_servo, q3_servo, q4_servo, q5_servo];

            % Checking joint limitations
            if all(q_candidate >= joint_limits(:,1)') && all(q_candidate <= joint_limits(:,2)')
                allSolutions = [allSolutions; q_candidate];
            end
        end
    end

    if isempty(allSolutions)
         q_sol = [];
         valid = false;
    else
         allSolutions = unique(round(allSolutions,6), 'rows');
         q_sol = allSolutions;
         valid = true;
    end
end

function [q_sol, valid] = numericalIK(p_des, q_prev, FK, jnt_limits, sumConstraint_rad, alpha, a, d, offset)
    tol = 1e-3;
    opts = optimoptions('fsolve','Algorithm','levenberg-marquardt',...
                'Display','none','MaxFunctionEvaluations',1e4,'MaxIterations',1e4);
                
    % Define the objective function with both positional error, angular constraints and penalties
    fun = @(q) [ FK(q) - p_des; 
                 (q(2) + q(3) + q(4)) - sumConstraint_rad];
             
    num_trials = 6;
    candidates = [];
    diffs = [];
    
    initial_guesses = cell(num_trials,1);
    initial_guesses{1} = q_prev;
    for k = 2:num_trials
         perturbation = (rand(size(q_prev)) - 0.5)*0.2;
         initial_guesses{k} = q_prev + perturbation;
    end

    for k = 1:num_trials
         q_guess = initial_guesses{k};
         [q_candidate, fval_vec, exitflag] = fsolve(fun, q_guess, opts);
         % Upper and lower cut-offs for each joint
         for j = 1:length(q_candidate)
             low = jnt_limits(j,1);
             high = jnt_limits(j,2);
             q_candidate(j) = max(low, min(high, q_candidate(j)));
         end
         candidate_fval = norm(fval_vec);
         if exitflag > 0 && candidate_fval < tol
             candidates = [candidates, q_candidate(:)];
             diffs = [diffs, norm(q_candidate - q_prev)];
         end
    end

    if ~isempty(candidates)
         [~, idx] = min(diffs);
         q_sol = candidates(:, idx)';
         valid = true;
    else
         warning('The numeric IK solution fails and returns to the previous solution.');
         q_sol = q_prev;
         valid = false;
         return;
    end
end

% groupSyncRead
function q = readAllJointAngles()
    global port_num PROTOCOL_VERSION dxl_lib_name DXL_ID1 DXL_ID2 DXL_ID3 DXL_ID4 ADDR_PRO_PRESENT_POSITION
    funcList = libfunctions(dxl_lib_name);
    if any(strcmp('groupSyncRead', funcList))
        fprintf('groupSyncRead detected. Using groupSyncRead for joint angle reading.\n');
        group_read = groupSyncRead(port_num, PROTOCOL_VERSION, ADDR_PRO_PRESENT_POSITION, 4);
        groupSyncReadAddParam(group_read, DXL_ID1);
        groupSyncReadAddParam(group_read, DXL_ID2);
        groupSyncReadAddParam(group_read, DXL_ID3);
        groupSyncReadAddParam(group_read, DXL_ID4);
        groupSyncReadTxRxPacket(group_read);
        pos1 = groupSyncReadGetData(group_read, DXL_ID1, ADDR_PRO_PRESENT_POSITION, 4);
        pos2 = groupSyncReadGetData(group_read, DXL_ID2, ADDR_PRO_PRESENT_POSITION, 4);
        pos3 = groupSyncReadGetData(group_read, DXL_ID3, ADDR_PRO_PRESENT_POSITION, 4);
        pos4 = groupSyncReadGetData(group_read, DXL_ID4, ADDR_PRO_PRESENT_POSITION, 4);
        groupSyncReadClearParam(group_read);
    else
        fprintf('groupSyncRead not found. Falling back to individual read calls.\n');
        pos1 = read4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID1), int32(ADDR_PRO_PRESENT_POSITION));
        pos2 = read4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID2), int32(ADDR_PRO_PRESENT_POSITION));
        pos3 = read4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID3), int32(ADDR_PRO_PRESENT_POSITION));
        pos4 = read4ByteTxRx(int32(port_num), int32(PROTOCOL_VERSION), int32(DXL_ID4), int32(ADDR_PRO_PRESENT_POSITION));
    end
    theta1 = (double(pos1)-2048)/4096*2*pi;
    theta2 = (double(pos2)-2048)/4096*2*pi;
    theta3 = (double(pos3)-2048)/4096*2*pi;
    theta4 = (double(pos4)-2048)/4096*2*pi;
    q = [theta1, theta2, theta3, theta4];
end

function sendTrajectory(q_traj, port_num, protocol, DXL_IDs, T_duration, FK_handle)
    global MAX_POS MIN_POS
    global ADDR_PRO_GOAL_POSITION
    global hEndEff hTrajectory globalTrajectory
    COUNTS_PER_REV = 4096;
    num_points = size(q_traj,2);
    dt = T_duration / num_points;
    for i = 1:num_points
        q_now = q_traj(:,i)';
        pos_cmd = zeros(1, length(DXL_IDs));
        for j = 1:length(DXL_IDs)
            pos_cmd(j) = round(q_now(j)/(2*pi)*COUNTS_PER_REV)+2048;
            pos_cmd(j) = max(MIN_POS, min(MAX_POS, pos_cmd(j)));
        end
        for j = 1:length(DXL_IDs)
            write4ByteTxRx(int32(port_num), int32(protocol), int32(DXL_IDs(j)), int32(ADDR_PRO_GOAL_POSITION), int32(pos_cmd(j)));
        end
        pause(dt);
    end
end

function q_traj = planJointSpaceTrajectory(q_start, q_end, T_total, N_points)
    if size(q_start,1) > 1, q_start = q_start(:).'; end
    if size(q_end,1) > 1, q_end = q_end(:).'; end
    t_way = [0, T_total];
    t_query = linspace(0, T_total, N_points);
    q_waypoints = [q_start; q_end]';
    vel_bc = zeros(4,2);
    acc_bc = zeros(4,2);
    q_traj_data = quinticpolytraj(q_waypoints, t_way, t_query, 'VelocityBoundaryCondition', vel_bc, 'AccelerationBoundaryCondition', acc_bc);
    q_traj = q_traj_data;
end

function q_traj = planCartesianSpaceTrajectory(p_start, p_end, T_total, N_points, q_init, FK, joint_limits, alpha, a, d, offset, constraint)
    if size(p_start,1) > 1, p_start = p_start(:).'; end
    if size(p_end,1) > 1, p_end = p_end(:).'; end
    if size(q_init,1) > 1, q_init = q_init(:).'; end
    t_way = [0, T_total];
    t_query = linspace(0, T_total, N_points);
    vel_zero = zeros(3,2);
    acc_zero = zeros(3,2);
    p_waypoints = [p_start; p_end]';
    cart_data = quinticpolytraj(p_waypoints, t_way, t_query, 'VelocityBoundaryCondition', vel_zero, 'AccelerationBoundaryCondition', acc_zero);
    q_traj = zeros(4, N_points);
    q_prev = q_init;
    for i = 1:N_points
        p_des = cart_data(:,i);
        [q_candidates, valid] = analyticalIK_withGamma(p_des, constraint, joint_limits);
        if ~valid
            warning('IK failed at sample %d -> fallback to previous q.', i);
            q_traj(:,i) = q_prev(:);
        else
            if i == 1
                diffs = vecnorm(q_candidates(:,1:4) - q_init, 2, 2);
                [~, idx] = min(diffs);
                q_sol = q_candidates(idx,1:4);
            else
                diffs = vecnorm(q_candidates(:,1:4) - q_prev, 2, 2);
                [~, idx] = min(diffs);
                q_sol = q_candidates(idx,1:4);
            end
            q_traj(:,i) = q_sol(:);
            q_prev = q_sol;
        end
    end
end

function q_traj = planCartesianSpaceTrajectory_numerical(p_start, p_end, T_total, N_points, q_init, FK, joint_limits, alpha, a, d, offset, constraint)
    if size(p_start,1) > 1, p_start = p_start(:).'; end
    if size(p_end,1) > 1, p_end = p_end(:).'; end
    if size(q_init,1) > 1, q_init = q_init(:).'; end
    t_way = [0, T_total];
    t_query = linspace(0, T_total, N_points);
    vel_zero = zeros(3,2);
    acc_zero = zeros(3,2);
    p_waypoints = [p_start; p_end]';
    cart_data = quinticpolytraj(p_waypoints, t_way, t_query, 'VelocityBoundaryCondition', vel_zero, 'AccelerationBoundaryCondition', acc_zero);
    q_traj = zeros(4, N_points);
    q_prev = q_init;
    for i = 1:N_points
        p_des = cart_data(:,i);
        [q_sol, valid] = numericalIK(p_des, q_prev, FK, joint_limits, constraint, alpha, a, d, offset);
        if ~valid
            warning('IK failed at sample %d -> fallback to previous q.', i);
            q_traj(:,i) = q_prev(:);
        else
            q_traj(:,i) = q_sol(:);
            q_prev = q_sol;
        end
    end
end

function q_traj = planStableTrajectory(q_target, N_points)
    if size(q_target,1) > 1, q_target = q_target(:).'; end
    q_traj = repmat(q_target(:), 1, N_points);
end

function keyPressCallback(~, event)
    global FK_4dof startP startQ endQ endP
    switch event.Key
        case 's'
            startQ = readAllJointAngles();
            startP = FK_4dof(startQ);
            fprintf('Captured START: P=[%.3f, %.3f, %.3f], Q=[%.3f, %.3f, %.3f, %.3f]\n',...
                startP(1), startP(2), startP(3), startQ(1), startQ(2), startQ(3), startQ(4));
        case 'g'
            endQ = readAllJointAngles();
            endP = FK_4dof(endQ);
            fprintf('Captured GOAL: P=[%.3f, %.3f, %.3f], Q=[%.3f, %.3f, %.3f, %.3f]\n',...
                endP(1), endP(2), endP(3), endQ(1), endQ(2), endQ(3), endQ(4));
    end
end