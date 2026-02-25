clear;
clc;
close all;
sca;

Screen('Preference', 'SkipSyncTests', 0);
Screen('Preference', 'VisualDebugLevel', 3);

% =========================================================================
% ⚙️ EXPERIMENT CONFIGURATION PARAMETERS
% =========================================================================
InitializePsychSound(1);

% ---  TRIGGER CONFIG (PORT SÉRIE) ---
config.useTriggers   = true;
config.pulseWidth    = 0.005;
config.serialPortDev = '/dev/ttyACM0';
config.serialBaud    = 115200;
config.serialHandle  = -1;
config.pinOneMask    = 1;

% --- Trigger Codes (valeurs AVANT forçage bit 0) ---
trig.startTrial      = 10;
trig.actionClick     = 20;
trig.toneOnset       = 30;
trig.judgementScreen = 40;
trig.responseClick   = 50;
trig.restingStart    = 60;
trig.restingEnd      = 62;
trig.crisisStart     = 70;
trig.crisisFixation  = 72;
trig.crisisSuccess   = 74;
trig.crisisFail      = 76;
trig.blockEnd        = 80;
trig.trainingTrial   = 90;
trig.badTrial        = 100;

% --- Hardware Check : PORT SÉRIE (Linux) ---
if config.useTriggers
    try
        try IOPort('CloseAll'); catch; end
%         portSettings = sprintf('BaudRate=%d DTR=1 RTS=1 ReceiveTimeout=0.1', ...
%                                config.serialBaud);

        portSettings = sprintf('BaudRate=%d, Parity=None, DataBits=8, StopBits=1' , ...
                               config.serialBaud);

        [config.serialHandle, errmsg] = IOPort('OpenSerialPort', ...
                                                config.serialPortDev, portSettings);
        if ~isempty(errmsg)
            warning('IOPort avertissement : %s', errmsg);
        end
        IOPort('Purge', config.serialHandle);
        IOPort('Write',  config.serialHandle, uint8(0));
        WaitSecs(0.01);
        fprintf('[TRIGGERS] Port série %s ouvert (handle=%d, baud=%d)\n', ...
                config.serialPortDev, config.serialHandle, config.serialBaud);
    catch ME
        warning('Impossible d''ouvrir le port série : %s\n', ME.message);
        config.useTriggers  = false;
        config.serialHandle = -1;
    end
end

% --- Global Constants ---
const.rotationTime           = 2.56;
const.minAngleForGoodTrial   = 360;
const.dotDurationBase        = 2;
const.dotDurationRandomRange = 0.25;
const.restingStateDuration   = 15; %150

% --- Audio Parameters ---
const.audioFreq              = 1000;
const.audioDuration          = 0.1;
const.audioSampleRate        = 44100;
const.triggerDelayOperant    = 0.245;
const.passiveWaitTimeBase    = 2.5;
const.passiveWaitTimeRange   = 2.5;

% --- Visual & Geometry Parameters ---
const.screenScaleFactor      = 0.5;
const.clockFaceScale         = 1.1;
const.clockTickScale         = 0.95;
const.dotRadius              = 15;
const.textSizeInstructions   = 20;
const.textSizePrompt         = 30;
const.textSizeStart          = 60;
const.textSizeExit           = 80;
const.lightGreyFactor        = 1.5;

% --- Alphabet/Clock Parameters ---
const.numAlphabets           = 42;
const.anglePerMin            = 360 / const.numAlphabets;
const.textOffset             = 1.23;

% --- Colors (Placeholder) ---
colors.white  = 255;
colors.black  = 0;
colors.redDot = [255 0 0];

% --- Instruction Text Parameters (FRENCH) ---
instructions.goal = 'Votre objectif général est d''indiquer avec précision la position de l''horloge au moment exact où l''événement cible s''est produit.\n\n';
instructions.block_title = 'CE BLOC REQUIERT :\n';

instructions.ba_action   = ' - ACTION : Vous devez effectuer un **clic volontaire avec la souris** au moment de votre choix.\n';
instructions.ba_judgment = ' - JUGEMENT : Indiquez la position de l''horloge au moment où vous avez **APPUYÉ SUR LA SOURIS**.\n\n';

instructions.bt_action   = ' - ACTION : N''appuyez sur aucune touche. Restez concentré en attendant un son.\n';
instructions.bt_judgment = ' - JUGEMENT : Indiquez la position de l''horloge au moment où vous avez **ENTENDU LE SON**.\n\n';

instructions.op_action_common = ' - ACTION : Vous devez effectuer un **CLIC SOURIS**. Cette action PROVOQUE immédiatement l''apparition d''un son.\n';
instructions.op_a_judgment    = ' - JUGEMENT : Indiquez la position de l''horloge au moment où vous avez **APPUYÉ SUR LA SOURIS** (la cause).\n\n';
instructions.op_t_judgment    = ' - JUGEMENT : Indiquez la position de l''horloge au moment où vous avez **ENTENDU LE SON** (l''effet).\n\n';

instructions.training_header  = '** MODE ENTRAINEMENT **\n\nCeci est un bloc d''entraînement.\nVos réponses ne seront PAS enregistrées dans les données finales.\n\n';


% =========================================================================
% --- CUSTOM INPUT GUI (AGRANDI) ---
% =========================================================================
participantID  = 'test';
sessionMode    = 'Base';

prefGroupName  = 'ExperimentPrefs';
prefKey        = 'LastSaveDirectory';
defaultSaveDir = pwd;
if ispref(prefGroupName, prefKey)
    lastDir = getpref(prefGroupName, prefKey);
    if exist(lastDir, 'dir')
        defaultSaveDir = lastDir;
    end
end

% --- GUI dimensions agrandies ---
guiW = 600;
guiH = 600;
screenSize = get(0, 'ScreenSize');
guiX = round((screenSize(3) - guiW) / 2);
guiY = round((screenSize(4) - guiH) / 2);

f = figure('Name', 'Configuration Expérience — Libet Clock', ...
           'Position', [guiX, guiY, guiW, guiH], ...
           'MenuBar', 'none', 'NumberTitle', 'off', 'Resize', 'off');
setappdata(f, 'saveDir', defaultSaveDir);

% Titre
uicontrol('Style', 'text', 'Position', [20, guiH-50, guiW-40, 35], ...
    'String', 'CONFIGURATION', ...
    'FontSize', 14, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

% Séparateur visuel
uicontrol('Style', 'text', 'Position', [20, guiH-60, guiW-40, 1], ...
    'BackgroundColor', [0.5 0.5 0.5]);

% ID Participant
yRow1 = guiH - 110;
uicontrol('Style', 'text', 'Position', [30, yRow1, 140, 25], ...
    'String', 'ID Participant :', 'FontSize', 11, 'HorizontalAlignment', 'left');
hID = uicontrol('Style', 'edit', 'Position', [180, yRow1, 300, 28], ...
    'String', participantID, 'FontSize', 11);

% Mode Session
yRow2 = yRow1 - 50;
uicontrol('Style', 'text', 'Position', [30, yRow2, 140, 25], ...
    'String', 'Mode Session :', 'FontSize', 11, 'HorizontalAlignment', 'left');
hMode = uicontrol('Style', 'popupmenu', 'Position', [180, yRow2, 300, 28], ...
    'String', {'Base', 'Post 1', 'Post 2', 'Training'}, 'FontSize', 11);

% Dossier de Sauvegarde
yRow3 = yRow2 - 200;
uicontrol('Style', 'text', 'Position', [30, yRow3+40, 400, 25], ...
    'String', 'Dossier de Sauvegarde :', 'FontSize', 11, 'HorizontalAlignment', 'center');
hDirDisplay = uicontrol('Style', 'text', 'Position', [30, yRow3, 360, 22], ...
    'String', defaultSaveDir, 'FontSize', 9, ...
    'HorizontalAlignment', 'left', 'ForegroundColor', [0 0.5 0]);
hBrowse = uicontrol('Style', 'pushbutton', 'Position', [400, yRow3, 120, 28], ...
    'String', 'Parcourir', 'FontSize', 10, ...
    'Callback', {@localBrowseCallback, f, hDirDisplay});

% Bouton DEMARRER
hStart = uicontrol('Style', 'pushbutton', ...
    'Position', [round((guiW-160)/2), 30, 160, 50], ...
    'String', 'DÉMARRER', 'FontSize', 13, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.2 0.7 0.3], 'ForegroundColor', [1 1 1], ...
    'Callback', 'uiresume(gcbf)', 'Enable', 'on');
setappdata(f, 'hStart', hStart);

uiwait(f);

if ~ishandle(f)
    error('Configuration annulée par l''utilisateur.');
end

saveDir = getappdata(f, 'saveDir');
if isempty(saveDir); error('Aucun dossier de sauvegarde sélectionné.'); end
setpref(prefGroupName, prefKey, saveDir);

participantID = get(hID, 'String');
modeItems     = get(hMode, 'String');
modeIndex     = get(hMode, 'Value');
sessionMode   = modeItems{modeIndex};
close(f);

isTrainingSession = strcmp(sessionMode, 'Training');

input('Appuyez sur Entrée dans la fenêtre de commande pour initialiser Audio/Écran...');
try PsychPortAudio('Close'); catch; end

% =========================================================================
% --- DEFINE BLOCK SEQUENCE ---
% =========================================================================

experimentSequence = [];

if strcmp(sessionMode, 'Base')
    experimentSequence = [experimentSequence; struct('cond','baseline','evt','tone',  'n',24)];
    experimentSequence = [experimentSequence; struct('cond','operant', 'evt','action','n',24)];
    experimentSequence = [experimentSequence; struct('cond','baseline','evt','action','n',24)];
    experimentSequence = [experimentSequence; struct('cond','operant', 'evt','tone',  'n',24)];
    experimentSequence = [experimentSequence; struct('cond','CRISIS',  'evt','CRISIS','n',0)];
    experimentSequence = [experimentSequence; struct('cond','operant', 'evt','action','n',8)];
    experimentSequence = [experimentSequence; struct('cond','baseline','evt','tone',  'n',8)];
    experimentSequence = [experimentSequence; struct('cond','operant', 'evt','tone',  'n',8)];
    experimentSequence = [experimentSequence; struct('cond','baseline','evt','action','n',8)];

elseif strcmp(sessionMode, 'Post 1')
    experimentSequence = [experimentSequence; struct('cond','CRISIS',  'evt','CRISIS','n',0)];
    experimentSequence = [experimentSequence; struct('cond','operant', 'evt','action','n',8)];
    experimentSequence = [experimentSequence; struct('cond','baseline','evt','tone',  'n',8)];
    experimentSequence = [experimentSequence; struct('cond','operant', 'evt','tone',  'n',8)];
    experimentSequence = [experimentSequence; struct('cond','baseline','evt','action','n',8)];

elseif strcmp(sessionMode, 'Post 2')
    experimentSequence = [experimentSequence; struct('cond','CRISIS',  'evt','CRISIS','n',0)];
    experimentSequence = [experimentSequence; struct('cond','baseline','evt','tone',  'n',8)];
    experimentSequence = [experimentSequence; struct('cond','operant', 'evt','tone',  'n',8)];
    experimentSequence = [experimentSequence; struct('cond','baseline','evt','action','n',8)];
    experimentSequence = [experimentSequence; struct('cond','operant', 'evt','action','n',8)];

elseif strcmp(sessionMode, 'Training')
    experimentSequence = [experimentSequence; struct('cond','baseline','evt','action','n',2)];
    experimentSequence = [experimentSequence; struct('cond','baseline','evt','tone',  'n',2)];
    experimentSequence = [experimentSequence; struct('cond','operant', 'evt','action','n',2)];
    experimentSequence = [experimentSequence; struct('cond','operant', 'evt','tone',  'n',2)];
end

% =========================================================================
% --- INITIALIZATION ---
% =========================================================================

screens      = Screen('Screens');
screenNumber = max(screens);

% Audio Setup
tTone = 0:1/const.audioSampleRate:const.audioDuration;
tone  = sin(2*pi*const.audioFreq*tTone);
tone  = [tone; tone];

reqlatencyclass = 3;
pahandleTone = PsychPortAudio('Open', [], 1, reqlatencyclass, const.audioSampleRate, 2);
PsychPortAudio('RunMode', pahandleTone, 1);
PsychPortAudio('FillBuffer', pahandleTone, tone);
warmupWhen = GetSecs + 0.01;
PsychPortAudio('Start', pahandleTone, 1, warmupWhen, 1);
PsychPortAudio('Stop', pahandleTone, 1);

colors.white     = WhiteIndex(screenNumber);
colors.black     = BlackIndex(screenNumber);
colors.lightGrey = colors.white / const.lightGreyFactor;

[window, windowRect] = PsychImaging('OpenWindow', screenNumber, colors.black);
HideCursor(screenNumber);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
[xCenter, yCenter] = RectCenter(windowRect);
ifi = Screen('GetFlipInterval', window);

Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
KbName('UnifyKeyNames');
Screen('Preference', 'TextRenderer', 1);
Screen('TextFont', window, 'Helvetica');
Screen('TextSize', window, const.textSizeInstructions);
escapeKey = KbName('Escape');

experimentStart = GetSecs();

% =========================================================================
% --- MAIN EXECUTION LOOP ---
% =========================================================================

try
    allBlocksResults = {};
    globalEventLog   = {};
    globalEventLog(end+1,:) = {0, 0, 0, 'ExperimentStarted', ...
        sprintf('Mode:%s ID:%s', sessionMode, participantID)};

    % =====================================================================
    %  1. RESTING STATE (sauf Training)
    % =====================================================================
    if ~isTrainingSession
        restLog = RunRestingState(window, windowRect, colors, const, trig, config, ...
                                  escapeKey, experimentStart, screenNumber);
        globalEventLog = [globalEventLog; restLog];
    else
        % Écran d'accueil Training
        Screen('TextSize', window, const.textSizeStart);
        DrawFormattedText(window, ...
            'MODE ENTRAÎNEMENT\n\nVous allez effectuer quelques essais de pratique.\nCes données ne compteront PAS pour l''expérience.\n\nCliquez pour commencer.', ...
            'center', 'center', colors.lightGrey);
        Screen('Flip', window);
        waitForClick(window);
        globalEventLog(end+1,:) = {GetSecs()-experimentStart, 0, 0, ...
            'TrainingSessionStart', ''};
    end

    % =====================================================================
    %  2. BLOCK ITERATION
    % =====================================================================
    blockCounter = 1;

    for b = 1:length(experimentSequence)
        blockDef = experimentSequence(b);

        if strcmp(blockDef.cond, 'CRISIS')
            % --- RUN CRISIS ---
            send_trigger(trig.crisisStart, config);
            crisisLog = RunCrisisValidation(window, windowRect, colors.white, ...
                            colors.lightGrey, const.textSizeInstructions, ...
                            escapeKey, trig, config, experimentStart, screenNumber);
            globalEventLog = [globalEventLog; crisisLog];

            Screen('TextSize', window, 30);
            DrawFormattedText(window, ...
                'Fin de la crise.\nCLIQUEZ pour reprendre les essais.', ...
                'center', 'center', colors.lightGrey);
            Screen('Flip', window);
            waitForClick(window);

        else
            % --- RUN EXPERIMENTAL BLOCK ---
            [blockResults, blockEventLog] = RunExperimentalBlock( ...
                window, windowRect, colors, const, instructions, trig, config, ...
                escapeKey, pahandleTone, ifi, ...
                blockDef.cond, blockDef.evt, blockDef.n, blockCounter, ...
                participantID, saveDir, experimentStart, isTrainingSession, screenNumber);

            allBlocksResults = [allBlocksResults; blockResults];
            globalEventLog   = [globalEventLog; blockEventLog];
            blockCounter     = blockCounter + 1;
        end
    end

    % =====================================================================
    %  3. SAVE
    % =====================================================================
    if ~exist(saveDir, 'dir'); mkdir(saveDir); end

    heading = { ...
        'BlockNum', 'TrialAttempt', 'Condition', 'EventReported', ...
        'TargetLetter', 'ActualAngle_deg', ...
        'SelectedLetter', 'SelectedAngle_deg', ...
        'AngularError_deg', 'PerceivedShift_ms', ...
        'ActionTimestamp_s', 'ToneOnsetTimestamp_s', ...
        'TotalAngleCovered_deg', 'StartAngle_deg', ...
        'JudgementRT_s', 'TrialValidity', 'AlphabetMapping'};

    globalEventLog(end+1,:) = {GetSecs()-experimentStart, 0, 0, 'ExperimentEnded', ''};
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    if isTrainingSession
        training_results_matrix = [heading; allBlocksResults];
        saveFileName = sprintf('%s_Training_%s_Results.mat', participantID, timestamp);
        save(fullfile(saveDir, saveFileName), ...
            'training_results_matrix', 'globalEventLog', ...
            'const', 'trig', 'sessionMode', 'participantID');
    else
        full_results_matrix = [heading; allBlocksResults];
        saveFileName = sprintf('%s_%s_%s_FullSession_Results.mat', ...
            participantID, sessionMode, timestamp);
        save(fullfile(saveDir, saveFileName), ...
            'full_results_matrix', 'globalEventLog', ...
            'const', 'trig', 'sessionMode', 'participantID');
    end
    fprintf('[SAVE] Données sauvegardées : %s\n', saveFileName);

    % =====================================================================
    %  4. END EXPERIMENT
    % =====================================================================
    PsychPortAudio('Close');
    if config.serialHandle >= 0
        IOPort('Write', config.serialHandle, uint8(0));
        IOPort('Close', config.serialHandle);
    end

    Screen('TextSize', window, const.textSizeExit);
    if isTrainingSession
        endMsg = 'Entraînement terminé.\n\nMerci !\nCliquez pour quitter.';
    else
        endMsg = 'Session terminée.\n\nMerci de votre participation.\nCliquez pour quitter.';
    end
    DrawFormattedText(window, endMsg, 'center', 'center', colors.lightGrey);
    Screen('Flip', window);
    waitForClick(window);
    ShowCursor(screenNumber);
    sca;

catch ME
    sca;
    try PsychPortAudio('Close'); catch; end
    if config.serialHandle >= 0
        try IOPort('Write', config.serialHandle, uint8(0)); catch; end
        try IOPort('Close', config.serialHandle); catch; end
    end
    ShowCursor;
    try
        crashSaveName = sprintf('%s_%s_CRASH_%s_Results.mat', ...
            participantID, sessionMode, datestr(now, 'yyyymmdd_HHMMSS'));
        save(fullfile(saveDir, crashSaveName), ...
            'allBlocksResults', 'globalEventLog');
        fprintf('[CRASH SAVE] %s\n', crashSaveName);
    catch
    end
    rethrow(ME);
end


% =========================================================================
% =========================================================================
%                         FONCTIONS
% =========================================================================
% =========================================================================


% =========================================================================
% RESTING STATE
% =========================================================================
function eventLog = RunRestingState(window, windowRect, colors, const, ...
                                     trig, config, escapeKey, experimentStart, screenNumber)
    eventLog = {};
    Screen('TextSize', window, const.textSizeInstructions);
    DrawFormattedText(window, ...
        'État de Repos\n\nFixez la croix au centre de l''écran.\nDétendez-vous pendant 2 minutes 30.\n\nCliquez pour commencer.', ...
        'center', 'center', colors.lightGrey);
    Screen('Flip', window);
    waitForClick(window);

    oldTextSize = Screen('TextSize', window, 50);
    DrawFormattedText(window, '+', 'center', 'center', colors.white);
    Screen('TextSize', window, oldTextSize);
    Screen('Flip', window);

    send_trigger(trig.restingStart, config);
    eventLog(end+1,:) = {GetSecs()-experimentStart, 0, 0, 'RestingStateStart', ...
                         sprintf('Duration=%.0fs', const.restingStateDuration)};

    startTime = GetSecs;
    while GetSecs - startTime < const.restingStateDuration
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown && keyCode(escapeKey)
            sca; error('Aborted during Resting State');
        end
        WaitSecs(0.1);
    end

    send_trigger(trig.restingEnd, config);
    eventLog(end+1,:) = {GetSecs()-experimentStart, 0, 0, 'RestingStateEnd', ''};

    DrawFormattedText(window, ...
        'Fin de la période de repos.\nCliquez pour continuer vers les essais.', ...
        'center', 'center', colors.lightGrey);
    Screen('Flip', window);
    waitForClick(window);
end


% =========================================================================
% MAIN EXPERIMENTAL BLOCK
% =========================================================================
function [all_results, blockEventLog] = RunExperimentalBlock( ...
    window, windowRect, colors, const, instructions, trig, config, ...
    escapeKey, pahandleTone, ifi, ...
    condType, eventType, numberOfTrials, blockNumber, ...
    participantID, saveDir, experimentStart, isTraining, screenNumber)

    % --- Logic flags ---
    isPassive    = false;
    playTone     = false;
    targetIsTone = false;

    if strcmp(condType, 'baseline') && strcmp(eventType, 'action')
        isPassive = false; playTone = false; targetIsTone = false;
    elseif strcmp(condType, 'baseline') && strcmp(eventType, 'tone')
        isPassive = true;  playTone = true;  targetIsTone = true;
    elseif strcmp(condType, 'operant') && strcmp(eventType, 'action')
        isPassive = false; playTone = true;  targetIsTone = false;
    elseif strcmp(condType, 'operant') && strcmp(eventType, 'tone')
        isPassive = false; playTone = true;  targetIsTone = true;
    end

    all_results   = {};
    blockEventLog = {};

    if isTraining
        blockLabel = sprintf('TRAINING_B%d', blockNumber);
    else
        blockLabel = sprintf('B%d', blockNumber);
    end

    % Show Instructions
    displayInstructions(window, colors.lightGrey, const.textSizeInstructions, ...
        condType, eventType, escapeKey, participantID, num2str(blockNumber), ...
        saveDir, instructions, isTraining);

    blockEventLog(end+1,:) = {GetSecs()-experimentStart, blockLabel, 0, 'BlockStart', ...
        sprintf('Cond:%s Evt:%s nTrials:%d Training:%d', condType, eventType, numberOfTrials, isTraining)};

    if isTraining
        send_trigger(trig.trainingTrial, config);
    end

    good_trial_count    = 0;
    trial_attempt_index = 1;
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);
    [xCenter, yCenter] = RectCenter(windowRect);

    while good_trial_count < numberOfTrials

        tonePlayed      = false;
        eventTriggered  = false;
        triggerTime     = 0;
        angleAtTrigger  = 0;
        angleAtTone     = 0;
        actionTimestamp = NaN;
        toneTimestamp   = NaN;
        judgementRT     = NaN;
        data = cell(const.numAlphabets, 3);

        % --- PRE-TRIAL INSTRUCTION SCREEN ---
        if isPassive
            actionText = 'Action : Rien (attendez le son)';
        else
            actionText = 'Action : Clic souris';
        end
        if targetIsTone
            judgeText = 'Jugement : Moment du SON';
        else
            judgeText = 'Jugement : Moment du CLIC';
        end

        Screen('TextSize', window, const.textSizeStart);
        instructionText = sprintf('Cliquez pour commencer l''essai\n\n%s\n%s', ...
                                   actionText, judgeText);
        if isTraining
            instructionText = ['[ENTRAÎNEMENT]\n\n', instructionText];
        end
        DrawFormattedText(window, instructionText, 'center', 'center', colors.lightGrey);
        Screen('Flip', window);
        waitForClick(window);
        WaitSecs(0.2);

        % --- SEND START TRIAL TRIGGER ---
        send_trigger(trig.startTrial, config);
        blockEventLog(end+1,:) = {GetSecs()-experimentStart, blockLabel, ...
            trial_attempt_index, 'TrialStart', ''};

        % --- PRE-COMPUTE TEXT BOUNDS ---
        Screen('TextSize', window, const.textSizePrompt);
        textBoundsAll = nan(const.numAlphabets, 4);
        for i = 1:const.numAlphabets
            [~, ~, textBoundsAll(i,:)] = DrawFormattedText(window, num2str(i), 0, 0, colors.lightGrey);
        end

        Priority(MaxPriority(window));

        % --- GEOMETRY ---
        circleDiameter = screenYpixels * const.screenScaleFactor;
        circleRadius   = circleDiameter / 2;

        % --- ALPHABET RANDOMIZATION ---
        AlphaBets = randomizedAlphabet(const.numAlphabets);

        % --- RANDOM START ANGLE ---
        initialAngle = rand * 360;
        dotDuration  = const.dotDurationBase + (rand * const.dotDurationRandomRange);

        % --- PASSIVE TIMING ---
        if isPassive
            passiveWaitTime = const.passiveWaitTimeBase + (rand * const.passiveWaitTimeRange);
        end

        totalAngleCovered = 0;
        continueLoop      = true;

        blockEventLog(end+1,:) = {GetSecs()-experimentStart, blockLabel, ...
            trial_attempt_index, 'AnimationStart', ...
            sprintf('StartAngle:%.2f', initialAngle)};

        % =================================================================
        % BUILD STATIC CLOCK FACE (OFFSCREEN)
        % =================================================================
        clockFaceTexture = Screen('OpenOffscreenWindow', window, colors.black, windowRect);
        Screen('BlendFunction', clockFaceTexture, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        Screen('TextFont', clockFaceTexture, 'Helvetica');
        Screen('TextSize', clockFaceTexture, const.textSizePrompt);

        clockRect = CenterRectOnPointd( ...
            [0 0 circleDiameter circleDiameter] * const.clockFaceScale, xCenter, yCenter);
        Screen('FillOval', clockFaceTexture, colors.black, clockRect, ...
            circleRadius*2*const.clockFaceScale);
        Screen('FrameOval', clockFaceTexture, colors.lightGrey, clockRect, 3);

        % Fixation cross
        Screen('TextSize', clockFaceTexture, 50);
        DrawFormattedText(clockFaceTexture, '+', 'center', 'center', colors.white);
        Screen('TextSize', clockFaceTexture, const.textSizePrompt);

        % Tick marks
        for i = 1:const.numAlphabets
            minAngle  = (i * const.anglePerMin) + 90;
            xposEnd   = circleRadius * const.clockFaceScale * sind(minAngle);
            yposEnd   = circleRadius * const.clockFaceScale * cosd(minAngle) * -1;
            xposStart = circleRadius * const.clockFaceScale * const.clockTickScale * sind(minAngle);
            yposStart = circleRadius * const.clockFaceScale * const.clockTickScale * cosd(minAngle) * -1;
            Screen('DrawLines', clockFaceTexture, ...
                [xposStart yposStart; xposEnd yposEnd]', 4, colors.lightGrey, ...
                [xCenter yCenter], 2);
        end

        % Letters around clock
        for i = 1:const.numAlphabets
            xpos = xCenter - const.textOffset * circleRadius * sind(const.anglePerMin*i - 90);
            ypos = yCenter + const.textOffset * circleRadius * cosd(const.anglePerMin*i - 90);
            DrawFormattedText(clockFaceTexture, AlphaBets(i), ...
                xpos - ((textBoundsAll(i,4)-textBoundsAll(i,2))/2), ...
                ypos + ((textBoundsAll(i,4)-textBoundsAll(i,2))/2), colors.lightGrey);
            data{i,1} = AlphaBets(i);
            data{i,2} = const.anglePerMin * i;
        end

        % =================================================================
        % ANIMATION LOOP — TIME-BASED ANGLE
        % =================================================================
        Screen('DrawTexture', window, clockFaceTexture);
        vblFirst       = Screen('Flip', window);
        trialAnimStart = vblFirst;
        if isPassive
            passiveStartTime = vblFirst;
        end
        vblPrev   = vblFirst;
        prevAngle = initialAngle;

        while continueLoop
            vblNow      = Screen('Flip', window, vblPrev + 0.5*ifi);
            elapsedTime = vblNow - trialAnimStart;
            currentAngle = mod(initialAngle + (elapsedTime / const.rotationTime) * 360, 360);

            % Accumulation angle total
            dAngle = currentAngle - prevAngle;
            if dAngle < -180; dAngle = dAngle + 360; end
            if dAngle > 180;  dAngle = dAngle - 360; end
            totalAngleCovered = totalAngleCovered + abs(dAngle);
            prevAngle = currentAngle;

            % Position du dot
            radianAngle = deg2rad(currentAngle);
            dotX = xCenter + const.clockTickScale * circleRadius * cos(radianAngle);
            dotY = yCenter + const.clockTickScale * circleRadius * sin(radianAngle);

            Screen('DrawTexture', window, clockFaceTexture);
            Screen('FillOval', window, colors.redDot, ...
                [dotX-const.dotRadius, dotY-const.dotRadius, ...
                 dotX+const.dotRadius, dotY+const.dotRadius]);

            % --- Escape ---
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown && keyCode(escapeKey)
                Screen('Close', clockFaceTexture);
                Priority(0);
                try PsychPortAudio('Close'); catch; end
                if config.serialHandle >= 0
                    try IOPort('Close', config.serialHandle); catch; end
                end
                sca; error('User Escape');
            end

            % --- CHECK FOR TRIGGER EVENT ---
            if ~eventTriggered
                if isPassive
                    if (vblNow - passiveStartTime) >= passiveWaitTime
                        eventTriggered  = true;
                        triggerTime     = vblNow;
                        angleAtTrigger  = currentAngle;
                        actionTimestamp = NaN;
                        blockEventLog(end+1,:) = {vblNow-experimentStart, blockLabel, ...
                            trial_attempt_index, 'PassiveTrigger', ...
                            sprintf('Angle:%.2f', angleAtTrigger)};
                    end
                else
                    [~, ~, buttons] = GetMouse(window);
                    if length(buttons) >= 1 && buttons(1)
                        eventTriggered = true;
                        triggerTime    = GetSecs();
                        clickElapsed   = triggerTime - trialAnimStart;
                        angleAtTrigger = mod(initialAngle + ...
                            (clickElapsed / const.rotationTime)*360, 360);
                        actionTimestamp = triggerTime - experimentStart;
                        send_trigger(trig.actionClick, config);
                        blockEventLog(end+1,:) = {triggerTime-experimentStart, ...
                            blockLabel, trial_attempt_index, 'UserClick', ...
                            sprintf('Angle:%.2f Time:%.4f', angleAtTrigger, actionTimestamp)};
                    end
                end
            end

            % --- PLAY TONE LOGIC ---
            if eventTriggered
                timeSinceTrigger = GetSecs() - triggerTime;

                if playTone && ~tonePlayed
                    triggerDelay = const.triggerDelayOperant;
                    if isPassive; triggerDelay = 0; end
                    if timeSinceTrigger >= triggerDelay
                        try
                            toneWave = sin(2*pi*const.audioFreq* ...
                                (0:1/const.audioSampleRate:const.audioDuration));
                            toneBuffer = [toneWave; toneWave];
                            PsychPortAudio('FillBuffer', pahandleTone, toneBuffer);

                            toneReqTime = GetSecs + 0.001;
                            PsychPortAudio('Start', pahandleTone, 1, toneReqTime, 1);
                            send_trigger(trig.toneOnset, config);
                            tonePlayed = true;

                            % Onset réel
                            toneStatus    = PsychPortAudio('GetStatus', pahandleTone);
                            realToneOnset = toneStatus.StartTime;
                            toneElapsed   = realToneOnset - trialAnimStart;
                            angleAtTone   = mod(initialAngle + ...
                                (toneElapsed / const.rotationTime)*360, 360);
                            toneTimestamp  = realToneOnset - experimentStart;

                            blockEventLog(end+1,:) = {realToneOnset-experimentStart, ...
                                blockLabel, trial_attempt_index, 'ToneOnset', ...
                                sprintf('Angle:%.2f RealOnset:%.4f', angleAtTone, toneTimestamp)};
                        catch ME_audio
                            fprintf('Audio Err: %s\n', ME_audio.message);
                            tonePlayed    = true;
                            angleAtTone   = currentAngle;
                            toneTimestamp  = GetSecs()-experimentStart;
                        end
                    end
                end

                if timeSinceTrigger >= dotDuration
                    continueLoop = false;
                end
            end

            vblPrev = vblNow;
        end
        % === END ANIMATION LOOP ===

        Priority(0);
        try PsychPortAudio('Stop', pahandleTone, 0); catch; end

        % --- Target angle ---
        if targetIsTone
            targetAngleTrial = angleAtTone;
        else
            targetAngleTrial = angleAtTrigger;
        end

        % --- Closest letter ---
        for i = 1:const.numAlphabets
            diff = targetAngleTrial - data{i,2};
            if diff > 180;  diff = diff - 360; end
            if diff < -180; diff = diff + 360; end
            data{i,3} = diff;
        end
        [~, idx] = min(abs(cell2mat(data(:,3))));
        targetLetter = data{idx,1};

        % --- Trial validity ---
        if totalAngleCovered >= const.minAngleForGoodTrial
            trialValidity = 'Good';
        else
            trialValidity = 'Bad';
        end

        % =================================================================
        % USER JUDGEMENT SCREEN
        % =================================================================
        Screen('TextSize', window, const.textSizePrompt);
        send_trigger(trig.judgementScreen, config);
        judgementOnset = GetSecs();
        blockEventLog(end+1,:) = {judgementOnset-experimentStart, blockLabel, ...
            trial_attempt_index, 'JudgementScreen', ''};

        Screen('DrawTexture', window, clockFaceTexture);

        textBoundsClick = nan(const.numAlphabets, 4);
        for i = 1:const.numAlphabets
            xpos = xCenter - const.textOffset*circleRadius * sind(const.anglePerMin*i - 90);
            ypos = yCenter + const.textOffset*circleRadius * cosd(const.anglePerMin*i - 90);
            textBoundsClick(i,:) = CenterRectOnPointd(textBoundsAll(i,:), xpos, ypos);
        end

        if targetIsTone
            actionStr = 'avez ENTENDU le SON';
        else
            actionStr = 'avez APPUYÉ sur la SOURIS';
        end
        msg = sprintf('Choisissez la lettre correspondant au moment où vous %s', actionStr);
        DrawFormattedText(window, msg, 'center', yCenter + 1.8*circleRadius, colors.lightGrey);
        Screen('Flip', window);

        SetMouse(xCenter, yCenter, window);
        ShowCursor(screenNumber);
        selectedIndex = 0;

        [~, ~, buttons] = GetMouse(window);
        while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.02); end

        while selectedIndex == 0
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown && keyCode(escapeKey)
                Screen('Close', clockFaceTexture);
                try PsychPortAudio('Close'); catch; end
                if config.serialHandle >= 0
                    try IOPort('Close', config.serialHandle); catch; end
                end
                sca; error('User Escape');
            end
            [mx, my, buttons] = GetMouse(window);
            for i = 1:const.numAlphabets
                rect = textBoundsClick(i,:);
                if IsPointInsideRectangle([mx, my], rect) && any(buttons)
                    selectedIndex = i;
                    send_trigger(trig.responseClick, config);
                    judgementRT = GetSecs() - judgementOnset;
                    blockEventLog(end+1,:) = {GetSecs()-experimentStart, blockLabel, ...
                        trial_attempt_index, 'ReportClick', ...
                        sprintf('Letter:%s RT:%.3f', AlphaBets(i), judgementRT)};
                    break;
                end
            end
        end
        HideCursor(screenNumber);

        % --- COMPUTE RESULTS ---
        selectedLetter = AlphaBets(selectedIndex);
        selectedAngle  = data{selectedIndex, 2};
        angDiff        = selectedAngle - targetAngleTrial;
        if angDiff > 180;  angDiff = angDiff - 360; end
        if angDiff < -180; angDiff = angDiff + 360; end
        perceivedShift_ms = angDiff * (const.rotationTime * 1000 / 360);

        % --- BUILD RESULT ROW (17 colonnes) ---
        resultRow = { ...
            blockNumber, ...
            trial_attempt_index, ...
            condType, ...
            eventType, ...
            targetLetter, ...
            targetAngleTrial, ...
            selectedLetter, ...
            selectedAngle, ...
            angDiff, ...
            perceivedShift_ms, ...
            actionTimestamp, ...
            toneTimestamp, ...
            totalAngleCovered, ...
            initialAngle, ...
            judgementRT, ...
            trialValidity, ...
            AlphaBets ...
        };

        all_results(end+1,:) = resultRow;

        % --- FREE TEXTURE ---
        Screen('Close', clockFaceTexture);

        % --- HANDLE BAD TRIAL ---
        if strcmp(trialValidity, 'Bad')
            send_trigger(trig.badTrial, config);
            Screen('TextSize', window, const.textSizeStart);
            DrawFormattedText(window, ...
                'Essai invalide (trop court).\n\nCLIQUEZ pour continuer.', ...
                'center', 'center', colors.lightGrey);
            Screen('Flip', window);

            blockEventLog(end+1,:) = {GetSecs()-experimentStart, blockLabel, ...
                trial_attempt_index, 'InvalidTrial', ...
                sprintf('AngleCovered:%.1f', totalAngleCovered)};
            waitForClick(window);
        else
            good_trial_count = good_trial_count + 1;
        end

        trial_attempt_index = trial_attempt_index + 1;
    end

    send_trigger(trig.blockEnd, config);
    blockEventLog(end+1,:) = {GetSecs()-experimentStart, blockLabel, ...
        trial_attempt_index-1, 'BlockEnd', ...
        sprintf('GoodTrials:%d TotalAttempts:%d', good_trial_count, trial_attempt_index-1)};
end


% =========================================================================
% CRISIS VALIDATION
% =========================================================================
function eventLog = RunCrisisValidation(window, windowRect, white, lightGrey, ...
                                         textSize, escapeKey, trig, config, ...
                                         experimentStart, screenNumber)
    eventLog = {};
    oldTextSize = Screen('TextSize', window);
    loop_crisis = true;

    eventLog(end+1,:) = {GetSecs()-experimentStart, 'CRISIS', 0, ...
                         'CrisisValidationScreen', 'Prompted'};

    while loop_crisis
        [~, ~, buttons] = GetMouse(window);
        while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.01); end

        Screen('TextSize', window, 50);
        DrawFormattedText(window, 'CLIQUEZ \npour démarrer la crise', ...
            'center', 'center', lightGrey);
        Screen('Flip', window);

        clicked = false;
        while ~clicked
            [~, ~, buttons] = GetMouse(window);
            if any(buttons); clicked = true; end
            [~, ~, keyCode] = KbCheck;
            if keyCode(escapeKey); sca; return; end
        end
        [~, ~, buttons] = GetMouse(window);
        while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.01); end

        Screen('TextSize', window, 50);
        DrawFormattedText(window, '+', 'center', 'center', white);
        send_trigger(trig.crisisFixation, config);
        eventLog(end+1,:) = {GetSecs()-experimentStart, 'CRISIS', 0, ...
                             'CrisisFixation', 'Cross displayed'};
        Screen('Flip', window);
        WaitSecs(0.5);

        clicked = false;
        while ~clicked
            [~, ~, buttons] = GetMouse(window);
            if any(buttons); clicked = true; end
            [~, ~, keyCode] = KbCheck;
            if keyCode(escapeKey); sca; return; end
        end
        [~, ~, buttons] = GetMouse(window);
        while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.01); end

        Screen('TextSize', window, 50);
        msg = 'Validation :\n\nClic GAUCHE = Crise RÉUSSIE\nClic DROIT = Crise ÉCHOUÉE';
        DrawFormattedText(window, msg, 'center', 'center', lightGrey);
        Screen('Flip', window);
        WaitSecs(0.2);

        validClick = false;
        isSuccess  = false;
        while ~validClick
            [~, ~, buttons] = GetMouse(window);
            if buttons(1)
                isSuccess  = true;
                validClick = true;
                send_trigger(trig.crisisSuccess, config);
                eventLog(end+1,:) = {GetSecs()-experimentStart, 'CRISIS', 0, ...
                                     'CrisisResult', 'SUCCESS'};
            elseif (length(buttons)>=2 && buttons(2)) || (length(buttons)>=3 && buttons(3))
                isSuccess  = false;
                validClick = true;
                send_trigger(trig.crisisFail, config);
                eventLog(end+1,:) = {GetSecs()-experimentStart, 'CRISIS', 0, ...
                                     'CrisisResult', 'FAIL'};
            end
            [~, ~, keyCode] = KbCheck;
            if keyCode(escapeKey); sca; return; end
        end

        [~, ~, buttons] = GetMouse(window);
        while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.02); end

        if isSuccess
            resultLabel = 'SUCCÈS';
            col = [0 255 0];
        else
            resultLabel = 'ÉCHEC';
            col = [255 0 0];
        end
        Screen('TextSize', window, 50);
        DrawFormattedText(window, sprintf('Résultat : %s', resultLabel), ...
            'center', 'center', col);
        Screen('Flip', window);
        WaitSecs(1.0);

        if ~isSuccess
            Screen('TextSize', window, 30);
            retryMsg = 'Voulez-vous recommencer ?\n\nClic GAUCHE = OUI\nClic DROIT = NON (Quitter)';
            DrawFormattedText(window, retryMsg, 'center', 'center', lightGrey);
            Screen('Flip', window);
            retryDecisionMade = false;
            while ~retryDecisionMade
                [~, ~, buttons] = GetMouse(window);
                if buttons(1)
                    retryDecisionMade = true;
                    loop_crisis = true;
                    eventLog(end+1,:) = {GetSecs()-experimentStart, 'CRISIS', 0, ...
                                         'CrisisRetry', 'User retry'};
                elseif (length(buttons)>=2 && buttons(2)) || (length(buttons)>=3 && buttons(3))
                    retryDecisionMade = true;
                    eventLog(end+1,:) = {GetSecs()-experimentStart, 'CRISIS', 0, ...
                                         'CrisisAbort', 'User quit'};
                    sca; error('Utilisateur a choisi de quitter après échec crise.');
                end
                [~, ~, keyCode] = KbCheck;
                if keyCode(escapeKey); sca; return; end
            end
            [~, ~, buttons] = GetMouse(window);
            while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.01); end
        else
            loop_crisis = false;
        end
    end
    Screen('TextSize', window, oldTextSize);
end


% =========================================================================
% DISPLAY INSTRUCTIONS
% =========================================================================
function displayInstructions(window, defaultColor, sz, condType, eventType, ...
                              escapeKey, participantID, blockNumber, saveDir, ...
                              instructions, isTraining)

    Screen('TextSize', window, round(sz * 1.5));
    Screen('TextFont', window, 'Helvetica');

    if isTraining
        p_final = instructions.training_header;
        p_final = [p_final, sprintf('BLOC ENTRAÎNEMENT %s\n\n', blockNumber)];
    else
        p_final = sprintf('BLOC %s\n\n', blockNumber);
    end

    p_final = [p_final, instructions.goal];
    p_final = [p_final, instructions.block_title];

    if strcmp(condType, 'baseline')
        if strcmp(eventType, 'action')
            p_final = [p_final, instructions.ba_action];
            p_final = [p_final, instructions.ba_judgment];
        elseif strcmp(eventType, 'tone')
            p_final = [p_final, instructions.bt_action];
            p_final = [p_final, instructions.bt_judgment];
        end
    elseif strcmp(condType, 'operant')
        p_final = [p_final, instructions.op_action_common];
        if strcmp(eventType, 'action')
            p_final = [p_final, instructions.op_a_judgment];
        elseif strcmp(eventType, 'tone')
            p_final = [p_final, instructions.op_t_judgment];
        end
    end

    p_final = [p_final, '\nCliquez avec la souris pour commencer le bloc d''essais'];
    DrawFormattedText(window, p_final, 'center', 'center', defaultColor, [], [], [], 1.5);
    Screen('Flip', window);

    [~, ~, buttons] = GetMouse(window);
    while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.01); end
    while true
        [~, ~, buttons] = GetMouse(window);
        if any(buttons); break; end
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyCode(escapeKey); sca; error('Quit in Instructions'); end
    end
    while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.01); end
    WaitSecs(0.2);
end


% =========================================================================
% RANDOMIZED ALPHABET (robust)
% =========================================================================
function randomizedList = randomizedAlphabet(numIterations)
    alphabets = 'ABCDEFGHKMNOPQRSUVWXYZ';
    noRepetitionRange = 8;
    maxAttempts = 1000;

    if nargin < 1
        numIterations = 42;
    end

    for attempt = 1:maxAttempts
        randomizedList = char(zeros(1, numIterations));
        success = true;
        for i = 1:numIterations
            lo = max(1, i - noRepetitionRange);
            forbidden = randomizedList(lo:i-1);
            validChars = setdiff(alphabets, forbidden);
            if isempty(validChars)
                success = false;
                break;
            end
            randomizedList(i) = validChars(randi(length(validChars)));
        end
        if success; return; end
    end
    warning('randomizedAlphabet: contraintes insatisfaites, fallback aléatoire');
    idx = randi(length(alphabets), 1, numIterations);
    randomizedList = alphabets(idx);
end


% =========================================================================
% UTILITY : IsPointInsideRectangle
% =========================================================================
function inside = IsPointInsideRectangle(point, rectangle)
    x = point(1); y = point(2);
    left = rectangle(1); top = rectangle(2);
    right = rectangle(3); bottom = rectangle(4);
    inside = (x >= left && x <= right && y >= top && y <= bottom);
end


% =========================================================================
% UTILITY : waitForClick (debounced)
% =========================================================================
function waitForClick(window)
    [~, ~, buttons] = GetMouse(window);
    while any(buttons)
        [~, ~, buttons] = GetMouse(window);
        WaitSecs(0.01);
    end
    while ~any(buttons)
        [~, ~, buttons] = GetMouse(window);
        WaitSecs(0.005);
    end
    while any(buttons)
        [~, ~, buttons] = GetMouse(window);
        WaitSecs(0.01);
    end
    WaitSecs(0.1);
end


% =========================================================================
% SEND TRIGGER (PORT SÉRIE, PIN 1 FORCÉ)
% =========================================================================
function send_trigger(val, config)
    if ~config.useTriggers || config.serialHandle < 0
        return;
    end
    val_out = bitor(uint8(val), uint8(config.pinOneMask));
    IOPort('Write', config.serialHandle, val_out);
    tEnd = GetSecs + config.pulseWidth;
    while GetSecs < tEnd; end
    IOPort('Write', config.serialHandle, uint8(0));
end


% =========================================================================
% GUI CALLBACK : Browse directory
% =========================================================================
function localBrowseCallback(~, ~, figHandle, hDirDisplay)
    selectedDir = uigetdir(pwd, 'Selectionner le dossier de sauvegarde');
    hStart = getappdata(figHandle, 'hStart');
    if selectedDir ~= 0
        setappdata(figHandle, 'saveDir', selectedDir);
        set(hDirDisplay, 'String', selectedDir, 'ForegroundColor', [0 0.5 0]);
        set(hStart, 'Enable', 'on');
    else
        currentDir = getappdata(figHandle, 'saveDir');
        if isempty(currentDir)
            set(hDirDisplay, 'String', 'Selection annulee !', 'ForegroundColor', [0.5 0 0]);
            set(hStart, 'Enable', 'off');
        end
    end
end