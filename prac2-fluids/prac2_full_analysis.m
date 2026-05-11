% =========================================================================
% ENGR30002 Practical 2: Centrifugal Pump - Full Analysis
% =========================================================================
% Generates: pump curves (a,b,c fits), theoretical system curve,
% operating point comparison, and figures for the lab report.
% =========================================================================

clear; clc; close all;

%% -------------------- Experimental data --------------------
% h_P (m) computed from P_kPa / 9.81  (since rho=1000, g=9.81 -> h=P*1000/(rho*g))

% Setting I (Slow)
P_slow = [32.5, 30, 27.5, 26, 25, 22.5, 20, 17.5, 15, 12.5, 10];
Q_slow = [0,    2.17, 3.75, 4.85, 6.06, 7.75, 10.60, 12.71, 14.90, 16.67, 20.65];

% Setting II (Mid)
P_mid  = [47, 45, 42.5, 40, 35, 32.5, 30, 27.5, 25, 22.5, 20];
Q_mid  = [0,  2.56, 5.61, 9.18, 13.64, 16.42, 18.18, 20.73, 23.00, 25.97, 28.40];

% Setting III (High)
P_high = [55, 52.5, 50, 47.5, 45, 42.5, 40, 37.5, 35, 32.5, 30];
Q_high = [0,  3.36, 8.18, 14.31, 17.04, 21.54, 23.50, 27.54, 30.30, 33.32, 36.36];

h_slow = P_slow / 9.81;
h_mid  = P_mid  / 9.81;
h_high = P_high / 9.81;

%% -------------------- Pump curve fits: h = a + b*Q^c --------------------
% Use lsqcurvefit
opts = optimoptions('lsqcurvefit','Display','off','MaxFunctionEvaluations',5000);
model = @(p,Q) p(1) + p(2).*Q.^p(3);

% --- Slow ---
p0 = [3.31, -0.1, 1.5];
[p_slow,~,res_s] = lsqcurvefit(model, p0, Q_slow, h_slow, [], [], opts);
SS_res_s = sum(res_s.^2);
SS_tot_s = sum((h_slow - mean(h_slow)).^2);
R2_slow = 1 - SS_res_s/SS_tot_s;

% --- Mid ---
p0 = [4.79, -0.1, 1.5];
[p_mid,~,res_m] = lsqcurvefit(model, p0, Q_mid, h_mid, [], [], opts);
SS_res_m = sum(res_m.^2);
SS_tot_m = sum((h_mid - mean(h_mid)).^2);
R2_mid = 1 - SS_res_m/SS_tot_m;

% --- High ---
p0 = [5.61, -0.1, 1.5];
[p_high,~,res_h] = lsqcurvefit(model, p0, Q_high, h_high, [], [], opts);
SS_res_h = sum(res_h.^2);
SS_tot_h = sum((h_high - mean(h_high)).^2);
R2_high = 1 - SS_res_h/SS_tot_h;

fprintf('\n========== PUMP CURVE FITS (h_P = a + b*Q^c) ==========\n');
fprintf('Setting    a (m)      b           c        R^2\n');
fprintf('Slow    %8.4f  %10.5f  %8.4f  %6.4f\n', p_slow(1),p_slow(2),p_slow(3),R2_slow);
fprintf('Mid     %8.4f  %10.5f  %8.4f  %6.4f\n', p_mid(1),p_mid(2),p_mid(3),R2_mid);
fprintf('High    %8.4f  %10.5f  %8.4f  %6.4f\n', p_high(1),p_high(2),p_high(3),R2_high);

%% -------------------- Theoretical system curve --------------------
% Constants
rho = 1000;       % kg/m^3 (water)
mu  = 1.0e-3;     % Pa.s
g   = 9.81;       % m/s^2
eps_pipe = 1.5e-6;% m (PVC ~ smooth, 0.0015 mm)

% Pipe geometry from prac brief
D25 = 0.025;  A25 = pi*D25^2/4;
D20 = 0.020;  A20 = pi*D20^2/4;
L25_total = 1.08 + 0.22;   % m (sections of DN25 combined)
L20 = 0.39;                % m

% K-values (minor losses)
K_entry    = 0.5;          % sharp-edged tank entrance (Cengel Table 8-4)
K_valve    = 0.2;          % gate valve, fully open
K_elbow    = 0.9;          % 90 deg threaded elbow
K_contract = 0.20;         % DN25 -> DN20 sudden contraction; d^2/D^2=(20/25)^2=0.64 -> K ~ 0.2
K_flowmeter= 2.7;          % given in prac brief
K_expand   = (1 - A20/A25)^2;  % sudden expansion DN20 -> DN25
K_exit     = 1.0;          % pipe -> tank

% Q sweep
Q_Lmin = linspace(0.01, 40, 400);   % L/min  (avoid Q=0 for log)
Q_si   = Q_Lmin * (1/60000);        % m^3/s
V25    = Q_si / A25;
V20    = Q_si / A20;

Re25 = rho*V25*D25/mu;
Re20 = rho*V20*D20/mu;

% Haaland equation for Fanning friction factor
fF = @(Re, eD) (1./(-1.8*log10((eD/3.7).^1.11 + 6.9./Re))).^2 / 4;
% Note: Haaland gives Darcy; divide by 4 for Fanning

eD25 = eps_pipe/D25;
eD20 = eps_pipe/D20;

fF_25 = fF(Re25, eD25);
fF_20 = fF(Re20, eD20);

% Head loss contributions (all in metres, using Fanning: h_f = 2f L/D V^2/g)
h_fric_25 = 2*fF_25 .* (L25_total/D25) .* V25.^2 / g;
h_fric_20 = 2*fF_20 .* (L20/D20)       .* V20.^2 / g;

h_entry    = K_entry    .* V25.^2 / (2*g);
h_valve    = K_valve    .* V25.^2 / (2*g);
h_elbows   = 2*K_elbow  .* V25.^2 / (2*g);
h_contract = K_contract .* V20.^2 / (2*g);
h_flowmtr  = K_flowmeter.* V20.^2 / (2*g);
h_expand   = K_expand   .* V20.^2 / (2*g);
h_exit     = K_exit     .* V25.^2 / (2*g);

h_sys = h_fric_25 + h_fric_20 + h_entry + h_valve + h_elbows + ...
        h_contract + h_flowmtr + h_expand + h_exit;

%% -------------------- Operating points: pump curve intersects system curve --------------------
findOp = @(p, Qrange) fzero(@(Q) (p(1)+p(2)*Q^p(3)) - interp1(Q_Lmin, h_sys, Q), Qrange);

Q_op_slow_th = findOp(p_slow, [1 25]);
h_op_slow_th = p_slow(1) + p_slow(2)*Q_op_slow_th^p_slow(3);

Q_op_mid_th  = findOp(p_mid,  [1 35]);
h_op_mid_th  = p_mid(1)  + p_mid(2) *Q_op_mid_th ^p_mid(3);

Q_op_high_th = findOp(p_high, [1 40]);
h_op_high_th = p_high(1) + p_high(2)*Q_op_high_th^p_high(3);

% Experimental operating points (max flow, valve fully open)
Q_op_slow_exp = 20.65; h_op_slow_exp = 10/9.81;
Q_op_mid_exp  = 28.40; h_op_mid_exp  = 20/9.81;
Q_op_high_exp = 36.36; h_op_high_exp = 30/9.81;

fprintf('\n========== OPERATING POINTS (valve fully open) ==========\n');
fprintf('Setting   Q_exp    h_exp     Q_theory  h_theory   %% diff Q\n');
fprintf('Slow    %6.2f   %6.3f    %6.2f    %6.3f    %+6.1f%%\n', Q_op_slow_exp, h_op_slow_exp, Q_op_slow_th, h_op_slow_th, 100*(Q_op_slow_th-Q_op_slow_exp)/Q_op_slow_exp);
fprintf('Mid     %6.2f   %6.3f    %6.2f    %6.3f    %+6.1f%%\n', Q_op_mid_exp,  h_op_mid_exp,  Q_op_mid_th,  h_op_mid_th,  100*(Q_op_mid_th -Q_op_mid_exp )/Q_op_mid_exp );
fprintf('High    %6.2f   %6.3f    %6.2f    %6.3f    %+6.1f%%\n', Q_op_high_exp, h_op_high_exp, Q_op_high_th, h_op_high_th, 100*(Q_op_high_th-Q_op_high_exp)/Q_op_high_exp);

%% -------------------- Reynolds sanity check at operating points --------------------
V25_op = (Q_op_high_exp/60000)/A25;
V20_op = (Q_op_high_exp/60000)/A20;
Re25_op = rho*V25_op*D25/mu;
Re20_op = rho*V20_op*D20/mu;
fprintf('\n========== FLOW REGIME CHECK (at Q=36.36 L/min) ==========\n');
fprintf('Re in DN25 pipe: %.0f  (turbulent if > 4000)\n', Re25_op);
fprintf('Re in DN20 pipe: %.0f  (turbulent if > 4000)\n', Re20_op);

%% -------------------- Sample friction factors at operating points --------------------
fprintf('\n========== FRICTION FACTORS AT Q=36.36 L/min ==========\n');
fF25_op = fF(Re25_op, eD25);
fF20_op = fF(Re20_op, eD20);
fprintf('f_Fanning DN25: %.5f\n', fF25_op);
fprintf('f_Fanning DN20: %.5f\n', fF20_op);

%% -------------------- Breakdown of head loss at Q_max_high --------------------
Q_check = Q_op_high_exp;  % L/min
Qsi_check = Q_check/60000;
V25c = Qsi_check/A25;
V20c = Qsi_check/A20;
Re25c = rho*V25c*D25/mu;
Re20c = rho*V20c*D20/mu;
fF25c = fF(Re25c, eD25);
fF20c = fF(Re20c, eD20);

fprintf('\n========== HEAD LOSS BREAKDOWN at Q=%.2f L/min ==========\n', Q_check);
hfb_25  = 2*fF25c*(L25_total/D25)*V25c^2/g;
hfb_20  = 2*fF20c*(L20/D20)      *V20c^2/g;
hfb_en  = K_entry   *V25c^2/(2*g);
hfb_va  = K_valve   *V25c^2/(2*g);
hfb_el  = 2*K_elbow *V25c^2/(2*g);
hfb_co  = K_contract*V20c^2/(2*g);
hfb_fm  = K_flowmeter*V20c^2/(2*g);
hfb_ex  = K_expand  *V20c^2/(2*g);
hfb_xt  = K_exit    *V25c^2/(2*g);
hfb_tot = hfb_25+hfb_20+hfb_en+hfb_va+hfb_el+hfb_co+hfb_fm+hfb_ex+hfb_xt;

fprintf('Pipe friction DN25 (1.30 m): %6.4f m\n', hfb_25);
fprintf('Pipe friction DN20 (0.39 m): %6.4f m\n', hfb_20);
fprintf('Pipe entrance (K=0.5):       %6.4f m\n', hfb_en);
fprintf('Gate valve open (K=0.2):     %6.4f m\n', hfb_va);
fprintf('2x 90 elbow (K=0.9 each):    %6.4f m\n', hfb_el);
fprintf('Contraction (K=0.20):        %6.4f m\n', hfb_co);
fprintf('Flow meter (K=2.7):          %6.4f m\n', hfb_fm);
fprintf('Expansion (K=%.3f):          %6.4f m\n', K_expand, hfb_ex);
fprintf('Pipe exit (K=1.0):           %6.4f m\n', hfb_xt);
fprintf('TOTAL h_sys:                 %6.4f m\n', hfb_tot);

%% -------------------- FIGURES --------------------
out_dir = '/Users/jincinga24/Documents/Playground/prac2-fluids';

% Figure 1: Q(c) experimental data only
figure('Position',[100 100 700 500],'Color','w');
hold on; grid on; box on;
plot(Q_slow,h_slow,'bo','MarkerSize',8,'MarkerFaceColor','b','DisplayName','Setting I (Slow)');
plot(Q_mid, h_mid, 'rs','MarkerSize',8,'MarkerFaceColor','r','DisplayName','Setting II (Mid)');
plot(Q_high,h_high,'k^','MarkerSize',8,'MarkerFaceColor','k','DisplayName','Setting III (High)');
xlabel('Flow rate Q (L/min)','FontSize',12);
ylabel('Pump head h_P (m)','FontSize',12);
title('Experimental pump performance curves','FontSize',13);
legend('Location','northeast','FontSize',11);
xlim([0 40]); ylim([0 6.5]);
saveas(gcf, fullfile(out_dir,'fig1_pump_curves_data.png'));

% Figure 2: Q(d) experimental data + fits
figure('Position',[100 100 700 500],'Color','w');
hold on; grid on; box on;
Q_fit = linspace(0,40,200);
plot(Q_slow,h_slow,'bo','MarkerSize',8,'MarkerFaceColor','b','DisplayName','Slow data');
plot(Q_fit, model(p_slow,Q_fit),'b-','LineWidth',1.5,'DisplayName','Slow fit');
plot(Q_mid, h_mid, 'rs','MarkerSize',8,'MarkerFaceColor','r','DisplayName','Mid data');
plot(Q_fit, model(p_mid,Q_fit),'r-','LineWidth',1.5,'DisplayName','Mid fit');
plot(Q_high,h_high,'k^','MarkerSize',8,'MarkerFaceColor','k','DisplayName','High data');
plot(Q_fit, model(p_high,Q_fit),'k-','LineWidth',1.5,'DisplayName','High fit');
xlabel('Flow rate Q (L/min)','FontSize',12);
ylabel('Pump head h_P (m)','FontSize',12);
title('Pump curves with fits  h_P = a + bQ^c','FontSize',13);
legend('Location','northeast','FontSize',10);
xlim([0 40]); ylim([0 6.5]);
saveas(gcf, fullfile(out_dir,'fig2_pump_curves_fits.png'));

% Figure 3: System curve alone
figure('Position',[100 100 700 500],'Color','w');
hold on; grid on; box on;
plot(Q_Lmin, h_sys, 'm-', 'LineWidth',2,'DisplayName','Theoretical system head');
xlabel('Flow rate Q (L/min)','FontSize',12);
ylabel('System head h_{sys} (m)','FontSize',12);
title('Theoretical system head curve (valve fully open)','FontSize',13);
legend('Location','northwest','FontSize',11);
xlim([0 40]); ylim([0 6.5]);
saveas(gcf, fullfile(out_dir,'fig3_system_curve.png'));

% Figure 4: Pump curves + system curve + operating points
figure('Position',[100 100 800 600],'Color','w');
hold on; grid on; box on;
plot(Q_fit, model(p_slow,Q_fit),'b-','LineWidth',2,'DisplayName','Slow pump curve');
plot(Q_fit, model(p_mid,Q_fit), 'r-','LineWidth',2,'DisplayName','Mid pump curve');
plot(Q_fit, model(p_high,Q_fit),'k-','LineWidth',2,'DisplayName','High pump curve');
plot(Q_Lmin, h_sys,'m--','LineWidth',2,'DisplayName','Theoretical system curve');

% Theoretical operating points
plot(Q_op_slow_th,h_op_slow_th,'bp','MarkerSize',14,'MarkerFaceColor','b','DisplayName','Theory operating pts');
plot(Q_op_mid_th, h_op_mid_th, 'bp','MarkerSize',14,'MarkerFaceColor','b','HandleVisibility','off');
plot(Q_op_high_th,h_op_high_th,'bp','MarkerSize',14,'MarkerFaceColor','b','HandleVisibility','off');

% Experimental operating points
plot(Q_op_slow_exp,h_op_slow_exp,'g*','MarkerSize',16,'LineWidth',2,'DisplayName','Experimental operating pts');
plot(Q_op_mid_exp, h_op_mid_exp, 'g*','MarkerSize',16,'LineWidth',2,'HandleVisibility','off');
plot(Q_op_high_exp,h_op_high_exp,'g*','MarkerSize',16,'LineWidth',2,'HandleVisibility','off');

xlabel('Flow rate Q (L/min)','FontSize',12);
ylabel('Head (m)','FontSize',12);
title('Pump curves vs theoretical system curve','FontSize',13);
legend('Location','northeast','FontSize',10);
xlim([0 40]); ylim([0 6.5]);
saveas(gcf, fullfile(out_dir,'fig4_operating_points.png'));

fprintf('\nAll figures saved to %s\n', out_dir);
fprintf('Done.\n');
