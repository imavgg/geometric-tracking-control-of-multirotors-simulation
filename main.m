% A simulation for geometric tracking control of multirotors
close all;

% simulation time
dt = 0.01;
sim_t = 10;

% initialize parameters
multirotor = multirotor_dynamics;
multirotor.dt = dt;
multirotor.sim_t = sim_t;
multirotor.t = 0:dt:sim_t;
multirotor.m = 4.34;
multirotor.J = [0.0820, 0, 0;
                0, 0.0845, 0;
                0, 0, 0.1377];
multirotor.d = 0.315;
multirotor.c_tau = 8.004e-4;
multirotor.x = zeros(3, length(multirotor.t));
multirotor.v = zeros(3, length(multirotor.t));
multirotor.R = zeros(9, length(multirotor.t));
multirotor.W = zeros(3, length(multirotor.t));
multirotor.ex = zeros(3, length(multirotor.t));
multirotor.ev = zeros(3, length(multirotor.t));
multirotor.eR = zeros(3, length(multirotor.t));
multirotor.eW = zeros(3, length(multirotor.t));
multirotor.R(1:9) = [1; 0; 0; 0; 1; 0 ;0 ; 0; 1];

% initialize trajectory
tra = zeros(12, length(multirotor.t));
traj = trajectory;

for i = 2:length(multirotor.t)
    t_now = multirotor.t(i);
    
    % desired trajectory
    tra(:, i) = traj.traj_generate(t_now);
    xd = tra(1:3, i-1);
    vd = tra(4:6, i-1);
    ad = tra(7:9, i-1);
    b1d = tra(10:12, i);
    Wd = [0; 0; 0];
    
    % now states
    x = multirotor.x(:, i-1);
    v = multirotor.v(:, i-1);
    R = reshape(multirotor.R(:, i-1), 3, 3);
    W = multirotor.W(:, i-1);
    e3 = multirotor.e3;
    
    % errors
    ex = x - xd;
    ev = v - vd;
    
    % control gains
    kx = diag([16*multirotor.m; 16*multirotor.m; 16*multirotor.m]);
    kv = diag([5.6*multirotor.m; 5.6*multirotor.m; 5.6*multirotor.m]);
    kR = 150;
    kW = 2.54;
    
    % f
    A = (-kx*ex - kv*ev + multirotor.m*ad + multirotor.m*multirotor.g*e3);
    b3 = R*e3;
    f = vec_dot(A, b3);
    
    % Rd
    norm_A = norm(A);
    b3d = A/norm_A;
    b2d = vec_cross(b3d, b1d);
    norm_b2d = norm(b2d);
    b2d = b2d/norm_b2d;
    b1d_proj = vec_cross(b2d, b3d);
    Rd = [b1d_proj b2d b3d];
    
    % eR and eW
    eR = 1/2*vee_map(Rd'*R - R'*Rd);
    eW = W - R'*Rd*Wd;
    
    % M
    M = -kR*eR - kW*eW + vec_cross(W, multirotor.J*W);
    
    % control input
    control = [f; M];
    
    % dynamics
    X0 = [x; v; reshape(R, 9, 1); W];
    [T, X_new] = ode45(@(t, x) multirotor.dynamics(t, x, control), [0, dt], X0, control);
    multirotor.x(:, i) = X_new(end, 1:3);
    multirotor.v(:, i) = X_new(end, 4:6);
    multirotor.R(:, i) = X_new(end, 7:15);
    multirotor.W(:, i) = X_new(end, 16:18);
    
    % save the error
    multirotor.ex(:, i) = ex;
    multirotor.ev(:, i) = ev;
    multirotor.eR(:, i) = eR;
    multirotor.eW(:, i) = eW;
end

figure(1)
subplot(3, 1, 1)
plot(multirotor.t, multirotor.x(1, :))
hold on
plot(multirotor.t, tra(1, :))
y = ylabel('X(m)', 'rotation', 0);
set(y, 'Units', 'Normalized', 'Position', [-0.09, 0.41])
legend('$X$', '$X_{d}$' , 'Interpreter', 'latex')
title('Trajectory and Desired Trajectory (m)')
subplot(3, 1, 2)
plot(multirotor.t, multirotor.x(2, :))
hold on
plot(multirotor.t, tra(2, :))
y = ylabel('Y(m)', 'rotation', 0);
set(y, 'Units', 'Normalized', 'Position', [-0.09, 0.41])
legend('$Y$', '$Y_{d}$' , 'Interpreter', 'latex')
subplot(3, 1, 3)
plot(multirotor.t, multirotor.x(3, :))
hold on
plot(multirotor.t, tra(3, :))
y = ylabel('Z(m)', 'rotation', 0);
set(y, 'Units', 'Normalized', 'Position', [-0.09, 0.41])
legend('$Z$', '$Z_{d}$' , 'Interpreter', 'latex')
xlabel('Time(sec)')
