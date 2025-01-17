% 清除之前生成的所有图形窗口
close all;

%% Sigma Delta ADC

% 设置参数
fs = 1024e3;       % 采样频率1024kHz
ts = 1/fs;         % 采样时间间隔
% amp = 2.5; 
amp = 0.25;        % 信号幅度
ff = 0.1e3;        % 信号频率100Hz
fft_point = 2^16;  % FFT点数65536
sim_tim = fft_point * ts;  % 仿真时间64ms

% 运行Simulink仿真
sim('sigma_delta_adc', sim_tim);

% 绘制输入的正弦波信号
 figure(1);
 plot(source); grid on;

% 绘制四级结构的总输出波形
 figure(2);
 stem(value3); grid on;

% 计算功率谱密度 (PSD)
[a1, b1] = pwelch(value1./sqrt(mean(value1.^2)), [], [], fft_point, fs, 'power');
[a2, b2] = pwelch(value2./sqrt(mean(value2.^2)), [], [], fft_point, fs, 'power');
[a3, b3] = pwelch(value3./sqrt(mean(value3.^2)), [], [], fft_point, fs, 'power');
[a4, b4] = pwelch(source./sqrt(mean(source.^2)), [], [], fft_point, fs, 'power');

% 绘制 PSD 图
figure(3);
plot(b1, pow2db(a1)); grid on; hold on;  % value1默认蓝色
plot(b2, pow2db(a2), 'r');               % value2红色
plot(b3, pow2db(a3), 'k');               % value3黑色
plot(b4, pow2db(a4), 'g');               % source绿色


hold off;

%% 将ADC输出导入到TXT文件

% fileID = fopen('adc_out.txt', 'w');
% 
% for i = 1:length(value3)
%     fprintf(fileID, '%d\n', value3(i));
% end
% 
% fclose(fileID);
% 
% disp('adc_out.mat has been exported to the adc_out.txt.');

%% CIC滤波器

% 定义CIC滤波器的抽取因子
r_cic = 64;

% 对输入信号sigma_delta_value3进行零填充，使其长度为64的倍数
value3 = [value3; zeros(ceil(length(value3)/64)*64 - length(value3), 1)];

% 创建一个CIC抽取滤波器对象
% r_cic: 抽取因子为64
% 1: 差分延迟为1（通常为1）
% 5: 滤波器的阶数为5
h_cic = dsp.CICDecimator(r_cic, 1, 5);

% 使用CIC滤波器对输入信号sigma_delta_value3进行抽取和滤波
cic_out = h_cic(value3);

figure(4);
subplot(6,1,1); plot(source); grid on; title('Source'); % 绘制原始信号
subplot(6,1,2); plot(value3); grid on; title('ADC');    % 绘制ADC输出的信号
subplot(6,1,3); plot(cic_out); grid on; title('CIC');   % 绘制CIC滤波后的信号

%% CIC补偿滤波器

% 定义补偿滤波器的抽取因子
r_comp = 2;

% 对输入信号 cic_out 进行零填充，使其长度为最近的 2 的幂次方
cic_out = [cic_out; zeros(ceil(length(cic_out)/2)*2-length(cic_out),1)];

% 例化补偿滤波器（CIC 补偿滤波器）

h_comp = design(fdesign.decimator(r_comp, 'ciccomp', 1, 5, 'fp,fst,ap,ast', 2e3, 6e3, 0.02, 60, fs/r_cic), 'SystemObject', true);

% 使用补偿滤波器对输入信号 cic_out 进行滤波和抽取
comp_out = h_comp(cic_out);

% 对滤波后的输出信号进行四舍五入取整
comp_out = round(comp_out);

% 绘制补偿滤波器输出的波形图
figure(4); 
subplot(6,1,4); plot(comp_out); grid on; title('CIC Compensation');

%% 半带滤波器

% 第一级半带滤波器
comp_out = [comp_out; zeros(ceil(length(comp_out)/2)*2-length(comp_out), 1)];   % 将输入信号填充为2的整数倍
h_hb1 = design(fdesign.decimator(2, 'halfband', 'tw,ast', 0.5, 40), 'equiripple', 'SystemObject', true);    % 生成滤波器对象
hb1_out = h_hb1(comp_out);      % 使用滤波器对象进行滤波和抽取
hb1_out = round(hb1_out);       % 四舍五入取整
figure(4); subplot(6, 1, 5); plot(hb1_out); grid on; title('hb1');

% 第二级半带滤波器
hb1_out = [hb1_out; zeros(ceil(length(hb1_out)/2)*2-length(hb1_out), 1)];
h_hb2 = design(fdesign.decimator(2, 'halfband', 'tw,ast', 0.2, 120), 'equiripple', 'SystemObject', true);
hb2_out = h_hb2(hb1_out);
hb2_out = round(hb2_out);
figure(4);
subplot(6, 1, 6); plot(hb2_out); grid on; title('hb2');
xlim([0, 150]);     % 设置 x 轴范围为 0 到 150
