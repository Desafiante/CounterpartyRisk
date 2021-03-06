tic
clear, clc

% --------------------------------------------------------------------
% Generate Correlation and Underlyings information
%
% In this block you must construct a correlation matrix, a list of
% underlyings, and a cell of underlyings. NOTICE that the three of them
% MUST be aligned!
%
% Generate a correlation matrix (if no WWR, mRho = diagonal_of_ones)

% Remember that the matrix is given in blocks, i.e, first diagonal block is
% the inter-spot correlations, second diagonal blocks is the inter-vol
% correlations, and anti-diagonal blocks are the spot-vol correlations.
%
% Input of correlation matrix is only an triangular matrix with ones on the
% diagonal.

mRho1 = [+1   +0.9  +0.0  -0.4  -0.4  -0.0; 
        +0.0  +1.0  +0.0  -0.4  -0.4  -0.0;
        +0.0  +0.0  +1.0  -0.0  -0.0  -0.0;
        +0.0  +0.0  +0.0  +1.0  +0.8  +0.0;
        +0.0  +0.0  +0.0  +0.0  +1.0  +0.0;
        +0.0  +0.0  +0.0  +0.0  +0.0  +1.0];
mRho2 = eye(6);

mRho = mRho1;
mRho = mRho + mRho' - eye(size(mRho));
 
% Generate list of underlyings 
stcListUnderlyings = {'Ford';'Repsol';'USD_YC'};

% Generate correlation structure (mRho + list of underlyings). Remember
% that mRho is aligned with the list of underlyings and that the first half 
% of mRho corresponds to spots and the second half to vols.
stcCorrelation = GenerateCorrelation(mRho,stcListUnderlyings);

% Generate structures for each underlying and store all in a cell
stcUnder1 = GenerateUnderlying('Ford',  10,0.05,0.0,0.8,0.3,3.8,1);
stcUnder2 = GenerateUnderlying('Repsol',10,0.05,0.0,0.5,0.3,3.8,1);
stcUnder3 = GenerateUnderlying('USD_YC',0.05,0.05,0.0,0.4,0.4,2.0,1.0);
cellUnderlyings = {stcUnder1;stcUnder2;stcUnder3};


% --------------------------------------------------------------------
% Generate structures for each trade and store all in a cell


%stcTrade1 = GenerateTrade('bsoptionput','Ford',100,5,10);
stcTrade1 = GenerateTrade('forward','Ford',0,3,10);
stcTrade2 = GenerateTrade('bsoptionput','Repsol',0,6,10);
stcTrade3 = GenerateTrade('IRswap','USD_YC',1,5,0.05);
cellTrades = {stcTrade1;stcTrade2;stcTrade3};
%cellTrades = {stcTrade3};


% --------------------------------------------------------------------
% Construct a structure for the Cpty.
stcDefault.default_type = 'NoWWR';
stcDefault.param1 = 1/3;
stcDefault.param2 = -1/0.37;   %-1/0.37
stcDefault.param3 = [];
stcDefault.param4 = [];
stcCpty = GenerateCounterparty('Ford',stcDefault);


% --------------------------------------------------------------------
% Define the simulation parameters
nNumSims = 10000;
t = 5;
dt = 10; %days per time steps
dnVar = 10; %MPR
stcSimParams = GenerateSimParams(nNumSims,t,dt,'constant',dnVar);
% Run !!!
[stcMeasuresCTE,stcCptyCTE,cellUnderlyingsCTE,cellTradesCTE] = fMCWrapper(cellUnderlyings,cellTrades,stcCpty,stcSimParams,stcCorrelation);


% Define the simulation parameters
stcUnder3 = GenerateUnderlying('USD_YC',0.05,0.05,0.0,1.0,0.4,2.0,1.0);
cellUnderlyings = {stcUnder1;stcUnder2;stcUnder3};
stcSimParams = GenerateSimParams(nNumSims,t,dt,'BK',dnVar);
% Run !!!
[stcMeasuresBK1,stcCptyBK1,cellUnderlyingsBK1,cellTradesBK1] = fMCWrapper(cellUnderlyings,cellTrades,stcCpty,stcSimParams,stcCorrelation);

% Define the simulation parameters
stcUnder3 = GenerateUnderlying('USD_YC',0.05,0.05,0.0,0.4,0.4,2.0,1.0);
cellUnderlyings = {stcUnder1;stcUnder2;stcUnder3};
stcSimParams = GenerateSimParams(nNumSims,t,dt,'BK',dnVar);
% Run !!!
[stcMeasuresBK2,stcCptyBK2,cellUnderlyingsBK2,cellTradesBK2] = fMCWrapper(cellUnderlyings,cellTrades,stcCpty,stcSimParams,stcCorrelation);

% Define the simulation parameters
stcUnder3 = GenerateUnderlying('USD_YC',0.05,0.05,0.0,0.2,0.4,2.0,1.0);
cellUnderlyings = {stcUnder1;stcUnder2;stcUnder3};
stcSimParams = GenerateSimParams(nNumSims,t,dt,'BK',dnVar);
% Run !!!
[stcMeasuresBK3,stcCptyBK3,cellUnderlyingsBK3,cellTradesBK3] = fMCWrapper(cellUnderlyings,cellTrades,stcCpty,stcSimParams,stcCorrelation);


%Calculate IM
stcIM_CTE = CalculateIM(stcMeasuresCTE);
stcIM_BK1 = CalculateIM(stcMeasuresBK1);
stcIM_BK2 = CalculateIM(stcMeasuresBK2);
stcIM_BK3 = CalculateIM(stcMeasuresBK3);

% --------------------------------------------------------------------
% Plot

% Play here (plot, run again, etc).
tvec = stcSimParams.tvec;
tvecVaR = stcSimParams.tvecVaR;

subplot(2,2,1)
p = plot(tvecVaR,stcMeasuresCTE.Collat.PFE99,'k');
set(p,'LineWidth',2)
title('PFE 99% - constant volatility','fontsize',12)
%hold on
ylim([0,0.13])
%hold off

subplot(2,2,2)
p = plot(tvecVaR,stcMeasuresBK1.Collat.PFE99,'g');
set(p,'LineWidth',2)
hold on
p = plot(tvecVaR,stcMeasuresBK2.Collat.PFE99,'r');
set(p,'LineWidth',2)
p = plot(tvecVaR,stcMeasuresBK3.Collat.PFE99,'b');
set(p,'LineWidth',2)
ylim([0,0.13])
title('PFE 99% - stochastic volatility','fontsize',12)
legend('Stress','Standard','Quiet','location','NorthEast')
hold off

subplot(2,2,3)
y = [stcIM_CTE,stcIM_BK1,stcIM_BK2,stcIM_BK3];
bar(y,'c');
ylim([0,0.12])
title('Initial Margin','fontsize',12)
text(1,0.002,'constant volatility','Rotation',90)

text(2,0.002,'stoch vol - stress','Rotation',90)

text(3,0.002,'stoch vol - stdrd','Rotation',90)

text(4,0.002,'stoch vol - quiet','Rotation',90)


% subplot(2,2,4)
% y = [stcEEPE_CTE.UnCollat,stcEEPE_BK1.UnCollat,stcEEPE_BK2.UnCollat,stcEEPE_BK3.UnCollat];
% bar(y);
% title('Regulatory Capital (EEPE)','fontsize',12)
% ylim([0,0.04])


%Save graph:
Folder = '/Users/CoolTips/Dropbox/MyPapers & MyResearch/mc_engine/MatLab/Working_matlab/Temp';
%saveas(gcf,[Folder '/Plot_IMreactivity.eps'],'psc2')









% COMPARE ONE METRIC BETWEEN WWR AND NO-WWR
% stcDefault.default_type = 'power';
% stcCpty = GenerateCounterparty('Ford',stcDefault);
% [stcMeasures2, stcCpty2,cellUnderlyings2,cellTrades2] = fMCWrapper(cellUnderlyings,cellTrades,stcCpty,stcSimParams,stcCorrelation);
% subplot(1,2,1)
% plot(tvec,stcMeasures1.UnCollat.EPE,'k')
% hold on
% plot(tvec,stcMeasures2.UnCollat.EPE,'b')
% ylim([0,1000])
% hold off
% subplot(1,2,2)
% plot(tvecVaR,stcMeasures1.Collat.EPE,'k')
% hold on
% plot(tvecVaR,stcMeasures2.Collat.EPE,'b')
% ylim([0 200])
% hold off

toc