function calculateTau()

plotDemoFigure = 0;

useHigh = 1; % use high-resolving or low-resolving bisection steps

forceMeasureRange = []; % range to measure tau over (empty for auto)

resFile = getOutputFile('bisection-output.mat');

if plotDemoFigure

    bisectionResults = load('C:\cygwin64\tmp\bisect-tau\output\bisection-output.mat', '-ascii');

else

    if ~exist(resFile, 'file')

        error('Could not find bisection results. Before using this command, run ./bisect-tau bisect mydut.cir');

    end

    load(resFile);

end

h = bisectionResults;

k = (h(:, 4) == useHigh) & ~isinf(h(:, 5));

h = h(k, :);

ts = h(:, 5); % settling time

te = ts - min(ts); % delay extension

windowSize = abs(h(:, 3) - h(end, 1)); % input event window size

% removing zero-sized windows

k = windowSize > 0; te = te(k); windowSize = windowSize(k);

% calculate automatic calculate range if neededs

if isempty(forceMeasureRange)

    forceMeasureRange = range(te) * [0.05 0.95];

end

% fitting

k = (te > forceMeasureRange(1)) & (te < forceMeasureRange(2));

windowSizeLog = log(windowSize);

f = polyfit(te(k), windowSizeLog(k), 1);

tau = -1/f(1);

Tw = exp(f(2));

winFun = @(clktoq) Tw * exp(-clktoq/tau);

% plotting

t = linspace(forceMeasureRange(1), forceMeasureRange(2), 100);

fh = figure();

clf; hold on;

h1 = plot(te * 1e9, windowSize, 'o');

h2 = plot(t * 1e9, winFun(t), '-k');

xlabel('Increase in clk-to-q Delay (ns)');

ylabel('Size of Input Event Window');

set(gca, 'yscale', 'log');

legend([h1 h2], {'Simulation Results', 'Exponential Fit'});

grid on; box on;

strTau = sprintf('Tau = %1.3e sec', tau);

strTw = sprintf('Tw  = %1.3e sec', Tw);

results = {
    'Results:'
    ''
    strTau
    strTw
    ''
    'Close figure window to exit.'
    };

for i=1:length(results);

    disp(results{i});

end

title(strTau);

if plotDemoFigure

    makeLines1pt();

    psvg('fig_exponential.svg', [10 8]);

else

    while ishandle(fh);

        drawnow

    end

end

end