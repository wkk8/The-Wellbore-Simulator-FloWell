function [rho, T, x, rhol, rhog, hl, hg] = water_iapws97_superheat(p, h)

% Thermodynamic properties of pure water, using IAPWS97
% Input is pressure [Pa] and enthalpy [J/kg]
% Outputs are density [kg/m^3], temperature [K], quality,
% liquid density [kg/m^3], vapor density [kg/m^3],
% liquid enthalpy [J/kg] and vapor enthalpy [J/kg].

Ts = p_reg4(p); % Saturation temperature

[rhol, hl] = water_reg1(p, Ts);
[rhog, hg] = water_reg2(p, Ts);

if p < 0
    error('Out of bounds, negative pressure')
end

if h < hl
    if Ts > 623.15
        error('Out of bounds, liquid Region 3');
    end
    x = 0;
    T = tph_reg1(p, h);
    rho = water_reg1(p, T);
elseif h > hg,
    T = fsolve(@(T) water_reg2_sol(T, p) - h, 1000);
    if p >= 16.5292e6
        theta = 0.57254459862746e3 + (((p*10^-6)/1 - 0.13918839778870e2)/0.10192970039326e-2)^(1/2);
        if T < theta
            error('Out of bounds, vapor Region 3');
        end
    end
    rho = water_reg2(p, T);
    x = 1;
    disp('Superheated steam')
else
    if Ts > 647.096
        error('Out of bounds, Maximum temp. for reg4 exceeded');
    end
    x = (h - hl) / (hg - hl);
    T = Ts;
    rho = 1 / (1 / rhol + 1 / rhog);
end

function T = p_reg4(p)
% Finds the temperature on the saturation curve

n = [0.11670521452767e4 -0.72421316703206e6 -0.17073846940092e2 ...
    0.12020824702470e5 -0.32325550322333e7 0.14915108613530e2 ...
    -0.48232657361591e4 0.40511340542057e6 -0.23855557567849 ...
    0.65017534844798e3]';

pc = 1e6;
beta = (p / pc).^(1/4);

E = beta.^2 + n(3)*beta + n(6);
F = n(1)*beta.^2 + n(4)*beta + n(7);
G = n(2)*beta.^2 + n(5)*beta + n(8);
D = 2 * G ./ (-F-(F.^2-4*E*G)^(1/2));

T = (n(10) + D - sqrt((n(10)+D).^2 - 4*(n(9)+n(10)*D))) / 2;


function T = tph_reg1(p, h)
% Stable single-phase liquid region
I = [0 0 0 0 0 0 1 1 1 1 1 1 1 2 2 3 3 4 5 6]';

J = [0 1 2 6 22 32 0 1 2 3 4 10 32 10 32 10 32 32 32 32]';

n = [-0.23872489924521e3 0.40421188637945e3 0.11349746881718e3 ...
    -0.58457616048039e1 -0.15285482413140e-3 -0.10866707695377e-5 ...
    -0.13391744872602e2 0.43211039183559e2 -0.54010067170506e2 ...
    0.30535892203916e2 -0.65964749423638e1 0.93965400878363e-2 ...
    0.11573647505340e-6 -0.25858641282073e-4 -0.40644363084799e-8 ...
    0.66456186191635e-7 0.80670734103027e-10 -0.93477771213947e-12 ...
    0.58265442020601e-14 -0.15020185953503e-16]';

hc = 2500e3;
pc = 1e6;

pi = p / pc;
eta = h / hc;

T = sum(n .* pi.^I .* (eta + 1).^J);


function [rho, h] = water_reg1(p,T)

I = [0 0 0 0 0 0 0 0 1 1 1 1 1 1 2 2 2 2 2 3 3 3 4 4 4 5 8 8 ...
    21 23 29 30 31 32]';

J = [-2 -1 0 1 2 3 4 5 -9 -7 -1 0 1 3 -3 0 1 3 17 -4 0 6 -5 ...
    -2 10 -8 -11 -6 -29 -31 -38 -39 -40 -41]';

n = [0.14632971213167 -0.84548187169114 -0.37563603672040e1 ...
    0.33855169168385e1 -0.95791963387872 0.15772038513228 ...
    -0.16616417199501e-1 0.81214629983568e-3 0.28319080123804e-3 ...
    -0.60706301565874e-3 -0.18990068218419e-1 -0.32529748770505e-1 ...
    -0.21841717175414e-1 -0.52838357969930e-4 -0.47184321073267e-3 ...
    -0.30001780793026e-3 0.47661393906987e-4 -0.44141845330846e-5 ...
    -0.72694996297594e-15 -0.31679644845054e-4 -0.28270797985312e-5 ...
    -0.85205128120103e-9 -0.22425281908000e-5 -0.65171222895601e-6 ...
    -0.14341729937924e-12 -0.40516996860117e-6 -0.12734301741641e-8 ...
    -0.17424871230634e-9 -0.68762131295531e-18 0.14478307828521e-19 ...
    0.26335781662795e-22 -0.11947622640071e-22 0.18228094581404e-23 ...
    -0.93537087292458e-25]';

pc = 16.53e6;
Tc = 1386;
R = 461.526;

pi = p / pc;
tau = Tc ./ T;

gamma = sum(n .* (7.1 - pi).^I .* (tau - 1.222).^J);
gamma_pi = sum(-n .* I .* (7.1 - pi).^(I-1) .* (tau - 1.222).^J);
gamma_tau = sum(n .* (7.1 - pi).^I .* J .* (tau - 1.222).^(J-1));

v = pi .* gamma_pi .* R .* T ./ p;
rho = 1 / v;
h = tau .* gamma_tau .* R .* T;


function h = water_reg2_sol(T, p)
[rho, h] = water_reg2(p, T);


function [rho, h] = water_reg2(p, T)

J0 = [0 1 -5 -4 -3 -2 -1 2 3]';
n0 = [-0.96927686500217e1 0.10086655968018e2 -0.56087911283020e-2 ...
    0.71452738081455e-1 -0.40710498223928 0.14240819171444e1 ...
    -0.43839511319450e1 -0.28408632460772 0.21268463753307e-1]';

pc = 1e6;
Tc = 540;
R = 461.526;

pi = p / pc;
tau = Tc ./ T;

gamma0 = log(pi) + sum(n0 .* tau.^J0);

I = [1 1 1 1 1 2 2 2 2 2 3 3 3 3 3 4 4 4 5 6 6 6 7 7 7 8 8 9 10 10 ...
    10 16 16 18 20 20 20 21 22 23 24 24 24]';

J = [0 1 2 3 6 1 2 4 7 36 0 1 3 6 35 1 2 3 7 3 16 35 0 11 25 8 36 13 ...
    4 10 14 29 50 57 20 35 48 21 53 39 26 40 58]';

n = [-0.17731742473213e-2 -0.17834862292358e-1 -0.45996013696365e-1 ...
    -0.57581259083432e-1 -0.50325278727930e-1 -0.33032641670203e-4 ...
    -0.18948987516315e-3 -0.39392777243355e-2 -0.43797295650573e-1 ...
    -0.26674547914087e-4 0.20481737692309e-7 0.43870667284435e-6 ...
    -0.32277677238570e-4 -0.15033924542148e-2 -0.40668253562649e-1 ...
    -0.78847309559367e-9 0.12790717852285e-7 0.48225372718507e-6 ...
    0.22922076337661e-5 -0.16714766451061e-10 -0.21171472321355e-2 ...
    -0.23895741934104e2 -0.59059564324270e-17 -0.12621808899101e-5 ...
    -0.38946842435739e-1 0.11256211360459e-10 -0.82311340897998e1 ...
    0.19809712802088e-7 0.10406965210174e-18 -0.10234747095929e-12 ...
    -0.10018179379511e-8 -0.80882908646985e-10 0.10693031879409 ...
    -0.33662250574171 0.89185845355421e-24 0.30629316876232e-12 ...
    -0.42002467698208e-5 -0.59056029685639e-25 0.37826947613457e-5 ...
    -0.12768608934681e-14 0.73087610595061e-28 0.55414715350778e-16 ...
    -0.94369707241210e-6]';

gammar = sum(n .* pi.^I .* (tau - 0.5).^J);

gamma = gamma0 + gammar;
gamma_pi = 1/pi + sum(n .* I .* pi.^(I-1) .* (tau - 0.5).^J);
gamma_tau = sum(n0 .* J0 .* tau.^(J0-1)) ...
    + sum(n .* pi.^I .* J .* (tau - 0.5).^(J-1));

v = pi * gamma_pi * R * T / p;
rho = 1 / v;
h = tau .* gamma_tau .* R .* T;

