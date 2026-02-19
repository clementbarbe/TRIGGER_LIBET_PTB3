clear; 
clc; 
close all; 
sca; 

Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'VisualDebugLevel', 3);

% =========================================================================
% ⚙️ EXPERIMENT CONFIGURATION PARAMETERS
% =========================================================================
InitializePsychSound(1);

% ---  TRIGGER CONFIG ---
config.useTriggers = true;       
config.pulseWidth  = 0.005;     

% --- Trigger Codes ---
trig.startTrial     = 10;
trig.actionClick    = 20;
trig.toneOnset      = 30;
trig.judgementScreen= 40; 
trig.responseClick  = 50;
trig.restingStart   = 70; 
trig.restingEnd     = 71; 
trig.crisisStart    = 80;
trig.crisisFixation = 81;
trig.crisisSuccess  = 82;
trig.crisisFail     = 83;
trig.blockEnd       = 90;

% --- Hardware Check ---
if config.useTriggers
    try
        OpenParPort; 
        WriteParPort(0);
        fprintf('Parport initialised\n');
    catch ME
        warning('Impossible to initialise ParPort\n');
        config.useTriggers = false; 
    end
end

% --- Global Constants ---
const.rotationTime = 2.56;            
const.minAngleForGoodTrial = 360;     
const.dotDurationBase = 2;            
const.dotDurationRandomRange = 0.25;  
const.restingStateDuration = 150; % 2min 30s

% --- Audio Parameters ---
const.audioFreq = 1000;               
const.audioDuration = 0.1;            
const.audioSampleRate = 44100;        
const.triggerDelayOperant = 0.245;    
const.passiveWaitTimeBase = 2.5;      
const.passiveWaitTimeRange = 2.5;     

% --- Visual & Geometry Parameters ---
const.screenScaleFactor = 0.5;       
const.clockFaceScale = 1.1;           
const.clockTickScale = 0.95;          
const.dotRadius = 15;                 
const.textSizeInstructions = 20;      
const.textSizePrompt = 30;            
const.textSizeStart = 60;             
const.textSizeExit = 80;              
const.lightGreyFactor = 1.5; 

% --- Alphabet/Clock Parameters ---
const.numAlphabets = 42;            
const.anglePerMin = 360 / const.numAlphabets; 
const.textOffset = 1.23;            

% --- Colors (Placeholder, defined after screen open) ---
colors.white = 255; 
colors.black = 0;   
colors.redDot = [255 0 0];

% --- Instruction Text Parameters (FRENCH) ---
instructions.goal = 'Votre objectif général est d''indiquer avec précision la position de l''horloge au moment exact où l''événement cible s''est produit.\n\n';
instructions.mechanics_title = 'MÉCANIQUE DE BASE :\n';
instructions.mechanics_dot = ' - Le point rouge tourne en continu et effectue une rotation complète en 2,56 secondes.\n';
instructions.mechanics_report = ' - Lorsque l''horloge s''arrête, cliquez sur la position du cadran correspondant au moment dont vous vous souvenez.\n\n';
instructions.block_title = 'CE BLOC REQUIERT :\n';
instructions.rules_title = 'RÈGLES CRITIQUES POUR ÉVITER LES RÉPONSES STÉRÉOTYPÉES :\n';
instructions.rules_1 = ' - N''appuyez pas pendant la première rotation complète de l''horloge.\n';
instructions.rules_2 = ' - Ne répondez pas de manière stéréotypée à un moment prédéterminé. Choisissez librement le moment de votre action.\n';

instructions.ba_action = ' - ACTION : Vous devez effectuer un **clic volontaire avec la souris** au moment de votre choix.\n';
instructions.ba_judgment = ' - JUGEMENT : Indiquez la position de l''horloge au moment où vous avez **APPUYÉ SUR LA SOURIS**.\n\n';

instructions.bt_action = ' - ACTION : N''appuyez sur aucune touche. Restez concentré en attendant un son.\n';
instructions.bt_judgment = ' - JUGEMENT : Indiquez la position de l''horloge au moment où vous avez **ENTENDU LE SON**.\n\n';

instructions.op_action_common = ' - ACTION : Vous devez effectuer un **clic volontaire avec la souris**. Cette action PROVOQUE immédiatement l''apparition d''un son.\n';
instructions.op_a_judgment = ' - JUGEMENT : Indiquez la position de l''horloge au moment où vous avez **APPUYÉ SUR LA SOURIS** (la cause).\n\n';
instructions.op_t_judgment = ' - JUGEMENT : Indiquez la position de l''horloge au moment où vous avez **ENTENDU LE SON** (l''effet).\n\n';


% =========================================================================
% --- CUSTOM INPUT GUI (Translated) ---
% =========================================================================
participantID = 'test';
sessionMode = 'Base'; % Default

prefGroupName = 'ExperimentPrefs';
prefKey = 'LastSaveDirectory';
defaultSaveDir = pwd; 

if ispref(prefGroupName, prefKey)
    lastDir = getpref(prefGroupName, prefKey);
    if exist(lastDir, 'dir')
        defaultSaveDir = lastDir;
    end
end

ui.pos = [400, 400, 350, 300]; 
ui.id_pos = [30, 220];
ui.mode_pos = [30, 170];
ui.dir_pos = [30, 100];
ui.button_pos = [125, 30, 100, 40];

f = figure('Name', 'Configuration Experience', 'Position', ui.pos, ...
           'MenuBar', 'none', 'NumberTitle', 'off', 'Resize', 'off');
setappdata(f, 'saveDir', defaultSaveDir);

uicontrol('Style', 'text', 'Position', [ui.id_pos, 100, 20], 'String', 'ID Participant :', 'HorizontalAlignment', 'left');
hID = uicontrol('Style', 'edit', 'Position', [ui.id_pos(1)+110, ui.id_pos(2), 160, 25], 'String', participantID);

uicontrol('Style', 'text', 'Position', [ui.mode_pos, 100, 20], 'String', 'Mode Session :', 'HorizontalAlignment', 'left');
hMode = uicontrol('Style', 'popupmenu', 'Position', [ui.mode_pos(1)+110, ui.mode_pos(2), 160, 25], 'String', {'Base', 'Post'});

uicontrol('Style', 'text', 'Position', [ui.dir_pos(1), ui.dir_pos(2)+30, 300, 20], 'String', 'Dossier de Sauvegarde :', 'HorizontalAlignment', 'left');
hDirDisplay = uicontrol('Style', 'text', 'Position', [ui.dir_pos(1), ui.dir_pos(2)+5, 250, 20], 'String', defaultSaveDir, 'HorizontalAlignment', 'left', 'ForegroundColor', [0 0.5 0]); 
hBrowse = uicontrol('Style', 'pushbutton', 'Position', [ui.dir_pos(1)+250, ui.dir_pos(2)+5, 70, 25], 'String', 'Parcourir', 'Callback', {@localBrowseCallback, f, hDirDisplay});
hStart = uicontrol('Style', 'pushbutton', 'Position', ui.button_pos, 'String', 'DEMARRER', 'Callback', 'uiresume(gcbf)', 'Enable', 'on'); 
setappdata(f, 'hStart', hStart);

uiwait(f);

if ~ishandle(f)
    error('Configuration annulee par l''utilisateur.');
end

saveDir = getappdata(f, 'saveDir');
if isempty(saveDir); error('Aucun dossier de sauvegarde selectionne.'); end
setpref(prefGroupName, prefKey, saveDir);

participantID = get(hID, 'String');
modeItems = get(hMode, 'String');
modeIndex = get(hMode, 'Value');
sessionMode = modeItems{modeIndex};
close(f);

input('Appuyez sur Entree dans la fenetre de commande pour initialiser l''Audio/Ecran...'); 
PsychPortAudio('close'); 

% =========================================================================
% --- DEFINE BLOCK SEQUENCE ---
% =========================================================================

experimentSequence = [];

if strcmp(sessionMode, 'Base')
    % --- SEQUENCE BASE ---
    experimentSequence = [experimentSequence; struct('cond', 'baseline', 'evt', 'tone',   'n', 2)];
    experimentSequence = [experimentSequence; struct('cond', 'operant',  'evt', 'action', 'n', 2)];
    experimentSequence = [experimentSequence; struct('cond', 'baseline', 'evt', 'action', 'n', 2)];
    experimentSequence = [experimentSequence; struct('cond', 'operant',  'evt', 'tone',   'n', 2)];
    experimentSequence = [experimentSequence; struct('cond', 'CRISIS', 'evt', 'CRISIS', 'n', 0)];
    experimentSequence = [experimentSequence; struct('cond', 'operant',  'evt', 'action', 'n', 8)];
    experimentSequence = [experimentSequence; struct('cond', 'baseline', 'evt', 'tone',   'n', 8)];
    experimentSequence = [experimentSequence; struct('cond', 'operant',  'evt', 'tone',   'n', 8)];
    experimentSequence = [experimentSequence; struct('cond', 'baseline', 'evt', 'action', 'n', 8)];
    
elseif strcmp(sessionMode, 'Post')
    % --- SEQUENCE POST ---
    experimentSequence = [experimentSequence; struct('cond', 'operant',  'evt', 'action', 'n', 8)];
    experimentSequence = [experimentSequence; struct('cond', 'baseline', 'evt', 'tone',   'n', 8)];
    experimentSequence = [experimentSequence; struct('cond', 'operant',  'evt', 'tone',   'n', 8)];
    experimentSequence = [experimentSequence; struct('cond', 'baseline', 'evt', 'action', 'n', 8)];
end


% =========================================================================
% --- INITIALIZATION ---
% =========================================================================

screens = Screen('Screens');
screenNumber = max(screens);

% Audio Setup
tTone = 0:1/const.audioSampleRate:const.audioDuration;
tone = sin(2*pi*const.audioFreq*tTone);
tone = [tone; tone];

reqlatencyclass = 3; 
pahandleTone = PsychPortAudio('Open', [], 1, reqlatencyclass, const.audioSampleRate, 2);
PsychPortAudio('RunMode', pahandleTone, 1);
PsychPortAudio('FillBuffer', pahandleTone, tone);
warmupWhen = GetSecs + 0.01;
PsychPortAudio('Start', pahandleTone, 1, warmupWhen, 1);
PsychPortAudio('Stop', pahandleTone, 1);

colors.white = WhiteIndex(screenNumber);
colors.black = BlackIndex(screenNumber);
colors.lightGrey = colors.white / const.lightGreyFactor;

[window, windowRect] = PsychImaging('OpenWindow', screenNumber, colors.black);
HideCursor; 
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
[xCenter, yCenter] = RectCenter(windowRect);
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
KbName('UnifyKeyNames');
Screen('Preference', 'TextRenderer', 1);
Screen('TextFont', window, 'Helvetica'); 
Screen('TextSize', window, const.textSizeInstructions); 
escapeKey = KbName('Escape');

% ⚡ GLOBAL TIMER START
experimentStart = GetSecs();

% =========================================================================
% --- MAIN EXECUTION LOOP ---
% =========================================================================

try
    % 1. RESTING STATE (Always first)
    RunRestingState(window, windowRect, colors, const, trig, config, escapeKey, experimentStart);
    
    % 2. BLOCK ITERATION
    blockCounter = 1;
    
    for b = 1:length(experimentSequence)
        blockDef = experimentSequence(b);
        
        if strcmp(blockDef.cond, 'CRISIS')
            % --- RUN CRISIS ---
             % ⚙️ TRIGGER: CRISIS START
            send_trigger(trig.crisisStart, config);
            RunCrisisValidation(window, windowRect, colors.white, colors.lightGrey, const.textSizeInstructions, escapeKey, trig, config, experimentStart);
            
            Screen('TextSize', window, 30);
            DrawFormattedText(window, 'Fin de la crise.\nCLIQUEZ pour reprendre les essais.', 'center', 'center', colors.lightGrey);
            Screen('Flip', window);
            
            % Debouncing Transition Phase
            [~, ~, buttons] = GetMouse(window);
            while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.01); end
            while ~any(buttons); [~, ~, buttons] = GetMouse(window); end
            while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.01); end 
            
        else
            % --- RUN EXPERIMENTAL BLOCK ---
            % Returns simplified results AND detailed event log
            [blockResults, blockEventLog] = RunExperimentalBlock(window, windowRect, colors, const, instructions, trig, config, escapeKey, pahandleTone, ...
                                                blockDef.cond, blockDef.evt, blockDef.n, blockCounter, participantID, saveDir, experimentStart);
            
            % Save immediately after block
            heading = {'TargetLetter', 'ActualAngle', 'Condition', 'SelectedLetter', 'TargetAngle', 'AngularDifference', 'PerceivedTime', 'EventReported', 'Angle before K.P', 'Good/Bad', 'StartAngle'};
            action_results_block = [heading; blockResults]; 
            
            if ~exist(saveDir, 'dir'); mkdir(saveDir); end
            saveFileName = sprintf('%s_%s_Block%02d_%s_%s_results.mat', participantID, sessionMode, blockCounter, blockDef.cond, blockDef.evt);
            
            % Saving both the simplified analysis matrix AND the detailed QC log
            save(fullfile(saveDir, saveFileName), 'action_results_block', 'blockEventLog');
            
            blockCounter = blockCounter + 1;
        end
    end
    
    % 3. END EXPERIMENT
    PsychPortAudio('Close');
    Screen('TextSize', window, const.textSizeExit);
    DrawFormattedText(window, 'Session terminée.\n\nMerci de votre participation.\nCliquez pour quitter.', 'center', 'center', colors.lightGrey);
    Screen('Flip', window);
    [~, ~, buttons] = GetMouse(window);
    while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.01); end
    while ~any(buttons); [~, ~, buttons] = GetMouse(window); end
    sca;

catch ME
    sca;
    PsychPortAudio('Close');
    rethrow(ME);
end


% =========================================================================
% --- LOGIC FUNCTIONS ---
% =========================================================================

function RunRestingState(window, windowRect, colors, const, trig, config, escapeKey, experimentStart)
    Screen('TextSize', window, const.textSizeInstructions);
    DrawFormattedText(window, 'État de Repos\n\nFixez la croix au centre de l''écran.\nDétendez-vous pendant 2 minutes 30.\n\nCliquez pour commencer.', 'center', 'center', colors.lightGrey);
    Screen('Flip', window);
    
    [~, ~, buttons] = GetMouse(window);
    while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.01); end
    while ~any(buttons); [~, ~, buttons] = GetMouse(window); end
    while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.2); end
    
    % Draw Fixation
    [xCenter, yCenter] = RectCenter(windowRect);
    fixCrossDimPix = 40;
    xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
    yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
    allCoords = [xCoords; yCoords];
    Screen('DrawLines', window, allCoords, 4, colors.white, [xCenter yCenter], 2);
    Screen('Flip', window);
    
    send_trigger(trig.restingStart, config);
    
    startTime = GetSecs;
    while GetSecs - startTime < const.restingStateDuration
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown && keyCode(escapeKey); sca; error('Aborted during Resting State'); end
        WaitSecs(0.1);
    end
    
    send_trigger(trig.restingEnd, config);
    
    DrawFormattedText(window, 'Fin de la période de repos.\nCliquez pour continuer vers les essais.', 'center', 'center', colors.lightGrey);
    Screen('Flip', window);
    
    [~, ~, buttons] = GetMouse(window);
    while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.01); end
    while ~any(buttons); [~, ~, buttons] = GetMouse(window); end
    while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.2); end
end


function [all_results, blockEventLog] = RunExperimentalBlock(window, windowRect, colors, const, instructions, trig, config, escapeKey, pahandleTone, condType, eventType, numberOfTrials, blockNumber, participantID, saveDir, experimentStart)
    
    % --- LOGIC CONFIG FOR BLOCK ---
    isPassive = false;      
    playTone  = false;      
    targetIsTone = false;   

    if strcmp(condType, 'baseline') && strcmp(eventType, 'action')
        isPassive = false; playTone = false; targetIsTone = false;
    elseif strcmp(condType, 'baseline') && strcmp(eventType, 'tone')
        isPassive = true; playTone = true; targetIsTone = true;
    elseif strcmp(condType, 'operant') && strcmp(eventType, 'action')
        isPassive = false; playTone = true; targetIsTone = false;
    elseif strcmp(condType, 'operant') && strcmp(eventType, 'tone')
        isPassive = false; playTone = true; targetIsTone = true;
    end
    
    all_results = {}; 
    % Initialize Event Log for this block: {Time, Block, Trial, EventType, Data}
    blockEventLog = {}; 
    
    % Show Instructions for this block
    displayInstructions(window, colors.lightGrey, const.textSizeInstructions, condType, eventType, escapeKey, participantID, num2str(blockNumber), saveDir, instructions);
    blockEventLog(end+1,:) = {GetSecs()-experimentStart, blockNumber, 0, 'BlockStart', sprintf('Cond:%s Evt:%s', condType, eventType)};
    
    good_trial_count = 0; 
    trial_attempt_index = 1;
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);
    [xCenter, yCenter] = RectCenter(windowRect);
    
    while good_trial_count < numberOfTrials
        tonePlayed = false;
        eventTriggered = false; 
        triggerTime = 0;
        angleAtTrigger = 0; 
        angleAtTone = 0;    
        data = cell(const.numAlphabets, 3); 
        tata = cell(1, 11); 
        
        Screen('TextSize', window, const.textSizeStart);
        DrawFormattedText(window, 'Cliquez avec la souris pour commencer l''essai', 'center', 'center', colors.lightGrey);
        Screen('Flip', window);
        
        [~,~,buttons] = GetMouse(window);
        while any(buttons); [~,~,buttons] = GetMouse(window); WaitSecs(0.005); end
        while true; [~,~,buttons] = GetMouse(window); if any(buttons); break; end; WaitSecs(0.005); end
        while any(buttons); [~,~,buttons] = GetMouse(window); WaitSecs(0.005); end
        WaitSecs(0.2); 
        
        send_trigger(trig.startTrial, config);
        blockEventLog(end+1,:) = {GetSecs()-experimentStart, blockNumber, trial_attempt_index, 'TrialStart', 'TriggerSent'};

        Screen('TextSize', window, const.textSizePrompt);
        textBoundsAll = nan(const.numAlphabets, 4);
        for i = 1:const.numAlphabets
            [~, ~, textBoundsAll(i, :)] = DrawFormattedText(window, num2str(i), 0, 0, colors.lightGrey);
        end
          
        Priority(MaxPriority(window));
          
        circleDiameter = (screenYpixels * const.screenScaleFactor);
        circleRadius = circleDiameter/2; 
        framesPerSecond = Screen('FrameRate', window); 
        framesForOneRotation = round(framesPerSecond * const.rotationTime); 
        rotationSpeed = 360 / framesForOneRotation;
        AlphaBets = randomizedAlphabet(); 
        angle = rand*360;
        initialAngle = angle; 
        dotDuration = const.dotDurationBase + (rand * const.dotDurationRandomRange); 
        
        passiveTriggerTime = 0;
        if isPassive
            passiveWaitTime = const.passiveWaitTimeBase + (rand * const.passiveWaitTimeRange); 
            startTime = GetSecs();
        end
        
        totalAngleCovered = 0;
        continueLoop = true;
        
        blockEventLog(end+1,:) = {GetSecs()-experimentStart, blockNumber, trial_attempt_index, 'AnimationStart', sprintf('StartAngle:%.2f', initialAngle)};

        % --- ANIMATION LOOP ---
        while continueLoop
            angle = angle + rotationSpeed;
            radianAngle = deg2rad(angle);
            dotX = xCenter + const.clockTickScale * circleRadius * cos(radianAngle);
            dotY = yCenter + const.clockTickScale * circleRadius * sin(radianAngle);
            
            clockRect = CenterRectOnPointd([0 0 circleDiameter circleDiameter] * const.clockFaceScale, xCenter, yCenter);
            Screen('FillOval', window, colors.black, clockRect, circleRadius*2 * const.clockFaceScale);
            Screen('FrameOval', window, colors.lightGrey, clockRect, 3);
            Screen('FillOval', window, colors.redDot, [dotX-const.dotRadius, dotY-const.dotRadius, dotX+const.dotRadius, dotY+const.dotRadius]);
            
            for i = 1:const.numAlphabets
                minAngle = (i * const.anglePerMin) + 90;
                xposEnd = circleRadius * const.clockFaceScale * sind(minAngle);
                yposEnd = circleRadius * const.clockFaceScale * cosd(minAngle) * -1;
                xposStart = circleRadius * const.clockFaceScale * const.clockTickScale * sind(minAngle);
                yposStart = circleRadius * const.clockFaceScale * const.clockTickScale * cosd(minAngle) * -1;
                Screen('DrawLines', window, [xposStart yposStart; xposEnd yposEnd]', 4, colors.lightGrey, [xCenter yCenter], 2);
            end
            
            for i = 1:const.numAlphabets
                xpos = xCenter - const.textOffset*circleRadius * sind(const.anglePerMin * i -90);
                ypos = yCenter + const.textOffset*circleRadius * cosd(const.anglePerMin * i -90);
                DrawFormattedText(window, AlphaBets(i),...
                    xpos - ((textBoundsAll(i, 4) - textBoundsAll(i, 2)) / 2),...
                    ypos + ((textBoundsAll(i, 4) - textBoundsAll(i, 2)) / 2), colors.lightGrey);
                data{i, 1} = AlphaBets(i);
                data{i, 2} = const.anglePerMin*i;
            end
            
            Screen('Flip', window);
            
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown && keyCode(escapeKey); PsychPortAudio('Close'); sca; error('User Escape'); end
            
            if ~eventTriggered
                totalAngleCovered = totalAngleCovered + rotationSpeed;
            end
            
            % --- CHECK FOR TRIGGERS ---
            if ~eventTriggered
                if isPassive
                    if (GetSecs() - startTime) >= passiveWaitTime
                        eventTriggered = true;
                        triggerTime = GetSecs();
                        angleAtTrigger = mod(angle, 360);
                        blockEventLog(end+1,:) = {GetSecs()-experimentStart, blockNumber, trial_attempt_index, 'PassiveTrigger', sprintf('Angle:%.2f', angleAtTrigger)};
                    end
                else
                    [~, ~, buttons] = GetMouse(window);
                    if length(buttons) >= 3 && buttons(1) 
                        eventTriggered = true;
                        triggerTime = GetSecs();
                        angleAtTrigger = mod(angle, 360);
                        send_trigger(trig.actionClick, config);
                        blockEventLog(end+1,:) = {GetSecs()-experimentStart, blockNumber, trial_attempt_index, 'UserClick', sprintf('Angle:%.2f', angleAtTrigger)};
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
                            when = GetSecs + 0.005;  
                            PsychPortAudio('Start', pahandleTone, 1, when, 1);                            
                            send_trigger(trig.toneOnset, config);
                            tonePlayed = true;
                            angleAtTone = mod(angle, 360);
                            blockEventLog(end+1,:) = {GetSecs()-experimentStart, blockNumber, trial_attempt_index, 'ToneOnset', sprintf('Angle:%.2f', angleAtTone)};
                        catch ME; fprintf('Audio Err: %s\n', ME.message); end
                    end
                end
                if timeSinceTrigger >= dotDuration; continueLoop = false; end
            end
        end
        % --- END ANIMATION LOOP ---
        
        if targetIsTone; targetAngleTrial = angleAtTone; else; targetAngleTrial = angleAtTrigger; end
        
        for i = 1:const.numAlphabets
            diff = targetAngleTrial - data{i, 2};
            if diff > 180; diff = diff - 360; elseif diff < -180; diff = diff + 360; end
            data{i, 3} = diff;
        end
        [~, idx] = min(abs(cell2mat(data(:, 3))));
        
        tata{1, 1} = data{idx, 1};      
        tata{1, 2} = targetAngleTrial;  
        tata{1, 3} = condType;          
        tata{1, 8} = eventType;         
        tata{1, 9} = totalAngleCovered;
        tata{1, 11} = initialAngle; 
        
        if totalAngleCovered >= const.minAngleForGoodTrial
            tata{1, 10} = 'Good Trial';
        else
            tata{1, 10} = 'Bad Trial';
        end
    
        % --- USER REPORT SCREEN ---
        Screen('TextSize', window, const.textSizePrompt);
        send_trigger(trig.judgementScreen, config);
        blockEventLog(end+1,:) = {GetSecs()-experimentStart, blockNumber, trial_attempt_index, 'JudgementScreen', ''};

        clockRect = CenterRectOnPointd([0 0 circleDiameter circleDiameter] * const.clockFaceScale, xCenter, yCenter);
        Screen('FillOval', window, colors.black, clockRect, circleRadius*2 * const.clockFaceScale);
        Screen('FrameOval', window, colors.lightGrey, clockRect, 3);
        
        for i = 1:const.numAlphabets
             minAngle = (i * const.anglePerMin) + 90;
             xposEnd = circleRadius * const.clockFaceScale * sind(minAngle);
             yposEnd = circleRadius * const.clockFaceScale * cosd(minAngle) * -1;
             xposStart = circleRadius * const.clockFaceScale * const.clockTickScale * sind(minAngle);
             yposStart = circleRadius * const.clockFaceScale * const.clockTickScale * cosd(minAngle) * -1;
             Screen('DrawLines', window, [xposStart yposStart; xposEnd yposEnd]', 4, colors.lightGrey, [xCenter yCenter], 2);
        end
          
        textBoundsClick = nan(const.numAlphabets, 4);
        for i = 1:const.numAlphabets
            xpos = xCenter - const.textOffset*circleRadius * sind(const.anglePerMin * i - 90);
            ypos = yCenter + const.textOffset*circleRadius * cosd(const.anglePerMin * i - 90);
            DrawFormattedText(window, AlphaBets(i),...
                xpos - ((textBoundsAll(i, 4) - textBoundsAll(i, 2)) / 2),...
                ypos + ((textBoundsAll(i, 4) - textBoundsAll(i, 2)) / 2), colors.lightGrey);
            textBoundsClick(i, :) = CenterRectOnPointd(textBoundsAll(i, :), xpos, ypos);
        end
              
        if targetIsTone
            actionStr = 'avez ENTENDU le SON';
        else
            actionStr = 'avez APPUYÉ sur la TOUCHE';
        end
        
        msg = sprintf('Choisissez la lettre correspondant au moment où vous %s', actionStr);

        DrawFormattedText(window, msg, 'center', yCenter + 2*circleRadius, colors.lightGrey);
        Screen('Flip', window);
          
        SetMouse(xCenter, yCenter, window);
        ShowCursor;
        selectedIndex = 0;
        
        [~, ~, buttons] = GetMouse(window);
        while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.02); end

        while selectedIndex == 0
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown && keyCode(escapeKey); PsychPortAudio('Close'); sca; error('User Escape'); end
            [mx, my, buttons] = GetMouse(window); 
            for i = 1:const.numAlphabets
                rect = textBoundsClick(i, :);
                if IsPointInsideRectangle([mx, my], rect) && any(buttons)
                    selectedIndex = i;
                    send_trigger(trig.responseClick, config);
                    blockEventLog(end+1,:) = {GetSecs()-experimentStart, blockNumber, trial_attempt_index, 'ReportClick', AlphaBets(i)};
                    break;
                end
            end
        end
        HideCursor; 
                                 
        tata{1, 4} = AlphaBets(selectedIndex);  
        tata{1, 5} = data{selectedIndex, 2};    
        diff = tata{1, 5} - tata{1, 2}; 
        if diff > 180; diff = diff - 360; elseif diff < -180; diff = diff + 360; end
        tata{1, 6} = diff; 
        tata{1, 7} = tata{1, 6} * (const.rotationTime * 1000 / 360); 
        all_results(trial_attempt_index, :) = tata(1, :);
        
        if strcmp(tata{1, 10}, 'Good Trial')
            good_trial_count = good_trial_count + 1; 
        else
            Screen('TextSize', window, const.textSizeStart);
            DrawFormattedText(window, 'Essai invalide (trop court).\n\nCLIQUEZ avec la souris pour continuer.', 'center', 'center', colors.lightGrey);
            Screen('Flip', window);
            [~, ~, buttons] = GetMouse(window);
            while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.5); end
            while ~any(buttons); [~, ~, buttons] = GetMouse(window); end
            while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.2); end 
        end
        trial_attempt_index = trial_attempt_index + 1;
    end
    
    send_trigger(trig.blockEnd, config);
    blockEventLog(end+1,:) = {GetSecs()-experimentStart, blockNumber, trial_attempt_index, 'BlockEnd', ''};
end

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
             set(hDirDisplay, 'String', 'Selection annulee ou invalide !', 'ForegroundColor', [0.5 0 0]);
             set(hStart, 'Enable', 'off'); 
        end
    end
end

function displayInstructions(window, defaultColor, size, condType, eventType, escapeKey, participantID, blockNumber, saveDir, instructions)
    Screen('TextSize', window, size * 1.5);
    Screen('TextFont', window, 'Helvetica');
    p_final = sprintf('BLOC %s\n\n', blockNumber);
    p_final = [p_final, instructions.goal];
    p_final = [p_final, instructions.mechanics_title];
    p_final = [p_final, instructions.mechanics_dot];
    p_final = [p_final, instructions.mechanics_report];
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
    p_final = [p_final, instructions.rules_title];
    p_final = [p_final, instructions.rules_1];
    p_final = [p_final, instructions.rules_2];
    p_final = [p_final, '\nCliquez avec la souris pour commencer le bloc d''essais'];
    DrawFormattedText(window, p_final, 'center', 'center', defaultColor, [], [], [], 1.5);
    Screen('Flip', window);
    
    [~, ~, buttons] = GetMouse(window);
    while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.01); end
    while true
        [x, y, buttons] = GetMouse(window);
        if any(buttons); break; end
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyCode(escapeKey); sca; error('Quit in Instructions'); end
    end
    while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.01); end
    WaitSecs(0.2);
end

function randomizedList = randomizedAlphabet()
   alphabets = 'ABCDEFGHKMNOPQRSUVWXYZ';
   numIterations = 42;
   noRepetitionRange = 8;
   randomizedList = char(zeros(1, numIterations));
   for i = 1:numIterations
       validChars = setdiff(alphabets, randomizedList(max(1, i-noRepetitionRange):i-1));
       validChars = setdiff(validChars, randomizedList(i+1:min(i+noRepetitionRange, numIterations)));
       randomizedList(i) = validChars(randi(length(validChars)));
   end
end

function inside = IsPointInsideRectangle(point, rectangle)
   x = point(1); y = point(2);
   left = rectangle(1); top = rectangle(2);
   right = rectangle(3); bottom = rectangle(4);
   inside = (x >= left && x <= right && y >= top && y <= bottom);
end

function RunCrisisValidation(window, windowRect, white, lightGrey, textSize, escapeKey, trig,  config, experimentStart)
    oldTextSize = Screen('TextSize', window);
    loop_crisis = true;
    while loop_crisis
        [~, ~, buttons] = GetMouse(window);
        while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.01); end

        Screen('TextSize', window, 50); 
        DrawFormattedText(window, 'CLIQUEZ \npour démarrer la crise', 'center', 'center', lightGrey);
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
        
        validClick = false; isSuccess = false;
        while ~validClick
            [~, ~, buttons] = GetMouse(window);
            if buttons(1)
                isSuccess = true; validClick = true;
                send_trigger(trig.crisisSuccess, config);
                
            elseif (length(buttons) >= 2 && buttons(2)) || (length(buttons) >= 3 && buttons(3))
                isSuccess = false; validClick = true;
                send_trigger(trig.crisisFail, config);
            end
            [~, ~, keyCode] = KbCheck;
            if keyCode(escapeKey); sca; return; end
        end
        
        [~, ~, buttons] = GetMouse(window);
        while any(buttons); [~, ~, buttons] = GetMouse(window); WaitSecs(0.02); end
        
        if isSuccess
            resultLabel = 'SUCCÈS'; col = [0 255 0]; 
        else
            resultLabel = 'ÉCHEC'; col = [255 0 0]; 
        end
        Screen('TextSize', window, 50);
        DrawFormattedText(window, sprintf('Résultat : %s', resultLabel), 'center', 'center', col);
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
                    retryDecisionMade = true; loop_crisis = true; 
                elseif (length(buttons) >= 2 && buttons(2)) || (length(buttons) >= 3 && buttons(3))
                    retryDecisionMade = true; sca; error('Utilisateur a choisi de quitter après échec crise.');
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

function send_trigger(val,  config)
    if config.useTriggers
        WriteParPort(val);
        tEnd = GetSecs + config.pulseWidth;
        while GetSecs < tEnd; end
        WriteParPort(0);
    else
        fprintf('[TRIGGER MOCK] Code sent: %d\n', val);
    end
end