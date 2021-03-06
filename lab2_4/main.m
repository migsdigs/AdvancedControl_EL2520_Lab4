%% Initialization 
s = tf('s');

%% Fetch Min and Non-min phase
%% min phase
sysmp = minphase;
[A,B,C,D] = ssdata(sysmp);

sysmp_mimo = ss(A,B,C,D,'StateName',{'Tank Level 1','Tank Level 2','Tank Level 3','Tank Level 4'},'InputName',{'Pump 1 Voltage (u1)','Pump 2 Voltage (u2)'},'OutputName',{'Lower Tank 1 (y1)','Lower Tank 2 (y2)'});
sysmp_tf = tf(sysmp_mimo);

poles_mp = pole(sysmp_tf);
zeros_mp = tzero(sysmp_tf);

G_mp = sysmp_tf;

%% non-min phase
sysnmp = nonminphase;
[A,B,C,D] = ssdata(sysnmp);

sysnmp_mimo = ss(A,B,C,D,'StateName',{'Tank Level 1','Tank Level 2','Tank Level 3','Tank Level 4'},'InputName',{'Pump 1 Voltage (u1)','Pump 2 Voltage (u2)'},'OutputName',{'Lower Tank 1 (y1)','Lower Tank 2 (y2)'});
sysnmp_tf = tf(sysnmp_mimo);

poles_nmp = pole(sysnmp_tf);
zeros_nmp = tzero(sysnmp_tf); 

G_nmp = sysnmp_tf;

%% 3.1 - Static Decoupling
%% 3.1.1 - Calculate static decoupling for system and plot Bode Diagrams of G_tilde for verification
%% Min phase case
G_mp = sysmp_tf;

W2_mp = eye(size(G_mp,1));
W1_mp = evalfr(inv(G_mp),0);

G_mp_tilde = W2_mp * G_mp * W1_mp;

%% Non-min phase case
G_nmp = sysnmp_tf;

W2_nmp = eye(size(G_nmp,1));
W1_nmp = evalfr(inv(G_nmp),0);

G_nmp_tilde = W2_nmp * G_nmp * W1_nmp;


% Plot Bode of G_mp_tilde
clf();
figure(1);
bodemag(G_mp_tilde);
hold on;
bodemag(G_nmp_tilde);
title('Bode plot of Static Decoupling');
legend('min phase','non-min phase')


%% 3.1.2 - Design a Diagonal Controller F_tilde for G_tilde
% Design as PI controller
% Phase Margin pi/3
% Cross over frequency 0.1 for mp case and 0.02 for nmp case

%% Min phase case
G_mp_tilde = G_mp_tilde;
w_c = 0.1;
pm = pi/3;

[mag_11, phase_11, wout_11] = bode(G_mp_tilde(1,1),w_c);
[mag_22, phase_22, wout_22] = bode(G_mp_tilde(2,2),w_c);

phase_11 = deg2rad(phase_11);
phase_22 = deg2rad(phase_22);

T_11 = tan(-pi + (pi/2) + pm - phase_11)/w_c;
T_22 = tan(-pi + (pi/2) + pm - phase_22)/w_c;

f_11 = (1+1/(s*T_11));
f_22 = (1+1/(s*T_22));
l_11 = G_mp_tilde(1,1)*f_11;
l_22 = G_mp_tilde(2,2)*f_22;

K_11 = 1/norm(evalfr(l_11,w_c*1i));
K_22 = 1/norm(evalfr(l_22,w_c*1i));

f_11 = K_11*f_11;
f_22 = K_22*f_22;

% Controllers

F_mp_tilde = [minreal(f_11),0;0,minreal(f_22)];
F_mp = evalfr(inv(G_mp),0) * F_mp_tilde;

%% Non-min Phase
G_nmp_tilde = G_nmp_tilde;
w_c = 0.02;
pm = pi/3;

[mag_11, phase_11, wout_11] = bode(G_nmp_tilde(1,1),w_c);
[mag_22, phase_22, wout_22] = bode(G_nmp_tilde(2,2),w_c);

phase_11 = deg2rad(phase_11);
phase_22 = deg2rad(phase_22);

T_11 = tan(-pi + (pi/2) + pm - phase_11)/w_c;
T_22 = tan(-pi + (pi/2) + pm - phase_22)/w_c;

f_11 = (1+1/(s*T_11));
f_22 = (1+1/(s*T_22));
l_11 = G_nmp_tilde(1,1)*f_11;
l_22 = G_nmp_tilde(2,2)*f_22;

K_11 = 1/norm(evalfr(l_11,w_c*1i));
K_22 = 1/norm(evalfr(l_22,w_c*1i));

f_11 = K_11*f_11;
f_22 = K_22*f_22;

% Controllers

F_nmp_tilde = [minreal(f_11),0;0,minreal(f_22)];
F_nmp = evalfr(inv(G_nmp),0) * F_nmp_tilde;

%% 3.1.3 - Calculate the Sinfular Values of the Sensitivity and Complementary Sensitivity Functions and plot them
% Sensitivity and Complementary Sensitivity of min phase
S_mp = minreal(inv(eye(2) + G_mp*F_mp));
T_mp = minreal((eye(2) + G_mp*F_mp) \ (G_mp*F_mp));

% Sensitivity and Complementary Sensitivity of non-min phase
S_nmp = minreal(inv(eye(2) + G_nmp*F_nmp));
T_nmp = minreal((eye(2) + G_nmp*F_nmp) \ (G_nmp*F_nmp));

% Plot Sensitivity
clf("reset");
figure(1);
sigma(S_mp); hold on; sigma(S_nmp);
title("Singular Values of Sensitivity");
legend('minimum phase', 'non-minimum phase')

% Plot Complementary Sensitivity
figure(2);
title("Singular Values of Complementary Sensitivity");
sigma(T_mp); hold on; sigma(T_nmp);
legend('minimum phase', 'non-minimum phase')


%% 3.1.4 - Simulate Closed Loop in Simulink
% Min Phase
F = F_mp;
G = G_mp;

sim('closedloop', 1000);
u_mp = uout;
y_mp = yout;

% Min Phase
F = F_nmp;
G = G_nmp;

sim('closedloop', 1000);
u_nmp = uout;
y_nmp = yout;

clf("reset");
figure(1);
subplot(1,2,1); plot(u_mp.Time,u_mp.Data); title('CL simulation of Input for Minimum Phase'); xlabel('Time (s)'); ylabel('U'); grid on;
subplot(1,2,2); plot(y_mp.Time, y_mp.Data); title('CL simulation of Output for Minmum Phase'); xlabel('Time (s)'); ylabel('Y'); grid on;

figure(2);
subplot(1,2,1); plot(u_nmp.Time,u_nmp.Data); title('CL simulation of Input for Non-Minimum Phase'); xlabel('Time (s)'); ylabel('U'); grid on;
subplot(1,2,2); plot(y_nmp.Time, y_nmp.Data); title('CL simulation of Output for Non-Minmum Phase'); xlabel('Time (s)'); ylabel('Y'); grid on;



%% 3.2 - Dynamic Decoupling
%% 3.2.1 - Calculate a dynamic decoupling W for the system and plot bode diagrams of G_tilde
%% Min Phase
wc = 0.1;
G_mp = G_mp;

RGA_mp = G_mp .* inv(G_mp)';
RGA_mp_wc = abs(evalfr(RGA_mp,1i*wc)); % seen to be almost perfect diagonal matrix

% Dynamical Decoupling
% let diagonal elements of W be 1, calculate off diagonal elements
w12_mp = -1*G_mp(1,2)/G_mp(1,1);
w21_mp = -1*G_mp(2,1)/G_mp(2,2);

W_mp = minreal([1,w12_mp;w21_mp,1]);
G_mp_tilde = tf(minreal(G_mp * W_mp));

% Check the static gain
G_mp_tilde_0 = evalfr(G_mp_tilde,0);

%% Non-Min Phase
wc = 0.02;
G_nmp = G_nmp;

RGA_nmp = G_nmp .* inv(G_nmp)';
RGA_nmp_wc = abs(evalfr(RGA_nmp,1i*wc)); % Not perfect diagonal, but diagonal elements closer to 1

% Dynamical Decoupling
% let diagonal elements of W be 1, calculate off diagonal elements
w12_nmp = -1*G_nmp(1,2)/G_nmp(1,1);
w21_nmp = -1*G_nmp(2,1)/G_nmp(2,2);

W_nmp = minreal([1,w12_nmp;w21_nmp,1]);
G_nmp_tilde = tf(minreal(ss(G_nmp * W_nmp)));

% Check the static gain
G_nmp_tilde_0 = evalfr(G_nmp_tilde,0);

% Change sign of W_nmp
% G_nmp_tilde = -1*G_nmp_tilde;
W_nmp = -1*W_nmp;
G_nmp_tilde = tf(minreal(G_nmp * W_nmp));

%% Plot Bode of G_tilde for min phase and non-min phase

% Plot Bode of G_mp_tilde
clf();
figure(1);
bodemag(G_mp_tilde);
hold on;
bodemag(G_nmp_tilde);
title('Bode plot of Dynamic Decoupling');
legend('min phase','non-min phase')


%% 3.2.2 - Design a Controller for G_tilde as PI controller
%% Min phase case
G_mp_tilde = G_mp_tilde;
w_c = 0.1;
pm = pi/3;

[mag_11, phase_11, wout_11] = bode(G_mp_tilde(1,1),w_c);
[mag_22, phase_22, wout_22] = bode(G_mp_tilde(2,2),w_c);

phase_11 = deg2rad(phase_11);
phase_22 = deg2rad(phase_22);

T_11 = tan(-pi + (pi/2) + pm - phase_11)/w_c;
T_22 = tan(-pi + (pi/2) + pm - phase_22)/w_c;

f_11 = (1+1/(s*T_11));
f_22 = (1+1/(s*T_22));
l_11 = G_mp_tilde(1,1)*f_11;
l_22 = G_mp_tilde(2,2)*f_22;

K_11 = 1/norm(evalfr(l_11,w_c*1i));
K_22 = 1/norm(evalfr(l_22,w_c*1i));

f_11 = K_11*f_11;
f_22 = K_22*f_22;

% Controllers

F_mp_tilde = [minreal(f_11),0;0,minreal(f_22)];
F_mp = minreal(W_mp * F_mp_tilde);

%% Non-min Phase
G_nmp_tilde = G_nmp_tilde;
w_c = 0.02;
pm = pi/3;

[mag_11, phase_11, wout_11] = bode(G_nmp_tilde(1,1),w_c);
[mag_22, phase_22, wout_22] = bode(G_nmp_tilde(2,2),w_c);

phase_11 = deg2rad(phase_11);
phase_22 = deg2rad(phase_22);

T_11 = tan(-pi + (pi/2) + pm - phase_11)/w_c;
T_22 = tan(-pi + (pi/2) + pm - phase_22)/w_c;

f_11 = (1+1/(s*T_11));
f_22 = (1+1/(s*T_22));
l_11 = G_nmp_tilde(1,1)*f_11;
l_22 = G_nmp_tilde(2,2)*f_22;

K_11 = 1/norm(evalfr(l_11,w_c*1i));
K_22 = 1/norm(evalfr(l_22,w_c*1i));

f_11 = K_11*f_11;
f_22 = K_22*f_22;

% Controllers

F_nmp_tilde = [minreal(f_11),0;0,minreal(f_22)];
F_nmp = minreal(W_nmp * F_nmp_tilde);

%% 3.2.3 - Calculate the Sinfular Values of the Sensitivity and Complementary Sensitivity Functions and plot them
% Sensitivity and Complementary Sensitivity of min phase
S_mp = minreal(inv(eye(2) + G_mp*F_mp));
T_mp = minreal((eye(2) + G_mp*F_mp) \ (G_mp*F_mp));

% Sensitivity and Complementary Sensitivity of non-min phase
S_nmp = minreal(inv(eye(2) + G_nmp*F_nmp));
T_nmp = minreal((eye(2) + G_nmp*F_nmp) \ (G_nmp*F_nmp));

% Plot Sensitivity
clf("reset");
figure(1);
sigma(S_mp); hold on; sigma(S_nmp);
title("Singular Values of Sensitivity");
legend('minimum phase', 'non-minimum phase')

% Plot Complementary Sensitivity
figure(2);
sigma(T_mp); hold on; sigma(T_nmp);
title("Singular Values of Complementary Sensitivity");
legend('minimum phase', 'non-minimum phase')


%% 3.2.4 - Simulate Closed Loop in Simulink
% Min Phase
F = F_mp;
G = G_mp;

sim('closedloop', 1000);
u_mp = uout;
y_mp = yout;

% Min Phase
F = F_nmp;
G = G_nmp;

sim('closedloop', 1000);
u_nmp = uout;
y_nmp = yout;

clf("reset");
figure(1);
subplot(1,2,1); plot(u_mp.Time,u_mp.Data); title('CL simulation of Input for Minimum Phase'); xlabel('Time (s)'); ylabel('U'); grid on;
subplot(1,2,2); plot(y_mp.Time, y_mp.Data); title('CL simulation of Output for Minmum Phase'); xlabel('Time (s)'); ylabel('Y'); grid on;

figure(2);
subplot(1,2,1); plot(u_nmp.Time,u_nmp.Data); title('CL simulation of Input for Non-Minimum Phase'); xlabel('Time (s)'); ylabel('U'); grid on;
subplot(1,2,2); plot(y_nmp.Time, y_nmp.Data); title('CL simulation of Output for Non-Minmum Phase'); xlabel('Time (s)'); ylabel('Y'); grid on;


%% 3.3 - Glover McFarlane Robust Loop Shaping
