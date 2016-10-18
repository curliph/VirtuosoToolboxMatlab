classdef cdsOutCorner < cdsOut
    %cdsOutCorner Cadence Simulation run results
    %   Collects the data from a single Cadence simulation corner.
    % 
    % See Also: cdsOutCorner/cdsOutCorner, cdsOutMatlab, cdsOutRun, cdsOutTest
    properties
        simNum
        analyses
        temp
        processCorner
        variables % sim variable values
        netlist
        names
        paths
        test
        result
    end
    properties (Access = private,Constant,Hidden)
        analysisTypes = {'tran-tran','stb-stb','stb-margin.stb','dcOp-dc'};
    end
    
    methods
        function obj = cdsOutCorner(varargin)
        % create a new cdsOutCorner object
        %
        % USE
        %  obj = cdsOutCorners(axlCurrentResultsPath, ...)
        % PARAMETERS
        %  signals - defines the signals to save
        %  transientSignals - defines the signals to save only for a
        %   transient analysis
        %  dcSignals - defines the signals to save only for a
        %   dc analysis
        %  desktop - Opens a new desktop if one isn't open yet (logical)
        %
        % See also: cdsOutCorner, cdsOutTest, cdsOutRun
            obj = obj@cdsOut(varargin{1:end}); % Superclass constructor
            
            % Basic Information and log
            if(nargin>=1)
                obj.paths.psf = char(varargin{1});
                obj.paths.psfLocFolders = strsplit(varargin{1},filesep);
                obj.getNames(obj.paths.psfLocFolders);
                obj.getPaths;
                obj.simNum = str2double(obj.paths.psfLocFolders{12});
            end
            % Parse Inputs
            p = inputParser;
            %p.KeepUnmatched = true;
            p.addOptional('axlCurrentResultsPath','',@ischar);
            p.addParameter('signals',[],@iscell);
            p.addParameter('transientSignals',[],@iscell);
            p.addParameter('dcSignals',[],@iscell);
            p.addParameter('desktop',false,@islogical);
%             p.addParameter('test',@islogical);
            p.parse(varargin{:});
            if(~isempty(p.Results.transientSignals))
                obj.analyses.transient.waveformsList = p.Results.transientSignals;
            elseif(~isempty(p.Results.signals))
                obj.analyses.transient.waveformsList = p.Results.signals;
            end
            if(~isempty(p.Results.dcSignals))
                obj.analyses.dc.waveformsList = p.Results.dcSignals;
            elseif(~isempty(p.Results.signals))
                obj.analyses.dc.waveformsList = p.Results.signals;
            end
            
            % Get files
            if(nargin>1)
                obj.getNetlist;
                obj.getSpectreLog;
                obj.getProcessCorner;
                if(isunix)
                    obj.loadAnalyses;
                    obj.getVariables;
                    obj.temp = obj.variables.temp;
                end
            end
        end
        function signalOut = loadSignal(obj,analysis,signal)
        % Loads a signal from an analysis
        %
        % USE
        %  obj.loadSignal(analysis,signal)
        % INPUTS
        %  analysis - analysis to load signal from (Char)
        %  signal -  signal name (Char)
        %
        % See also: cdsOutMatlab
            analysis = lower(analysis);
            switch analysis
                case {'transient','tran-tran','tran','trans'}
                    cdsAnalysisName = 'tran-tran';
                    analysis = 'transient';
                otherwise
                    warning('Wrong or unsupported analysis type');
            end
        	signalOut = cds_srr( obj.paths.psf, cdsAnalysisName, signal);
            obj.data.(analysis).(signal) = signalOut;
        end
        function getAllProperties(obj,analysis)
        % get all the properties of an analysis
        %
        % USE
        %  obj.getAllProperties(analysis);
        %   places the properties in the analysis's struct
        %
            obj.analyses.(analysis).properties.list = cds_srr(obj.paths.psf,analysis);
            properties = obj.analyses.(analysis).properties.list.prop;
            for i = 1:length(properties)
                obj.analyses.(analysis).properties.(regexprep(properties{i},'\(|\)|\.| ','')) = ...
                cds_srr(obj.paths.psf,analysis,properties{i});
            end
        end
        function loadAnalyses(obj)
            obj.info.datasets = cds_srr(obj.paths.psf);
            obj.info.availableAnalyses = intersect(obj.info.datasets,obj.analysisTypes);
            if(any(strcmp('stb-stb',obj.info.availableAnalyses)))
                obj.getDataSTB;
            end
            if(any(strcmp('dc-dc',obj.info.availableAnalyses)))
                obj.getDataDC;
            end
            
            if(any(strcmp('tran-tran',obj.info.availableAnalyses)))
                obj.getDataTransient;
            end
            if(any(strcmp('dcOp-dc',obj.info.availableAnalyses)))
                obj.getDataDCop;
            end
        end
        function getNames(obj,psfLocFolders)
            obj.names.project = psfLocFolders{5};
            obj.names.result = psfLocFolders{11};
            obj.names.user = psfLocFolders{4};
            obj.names.library = psfLocFolders{6};
            obj.names.testBenchCell = psfLocFolders{7};
            obj.names.test = psfLocFolders{13};
        end
        function getPaths(obj)
            obj.paths.project = char(strjoin({'','prj',obj.names.project},filesep));
            obj.paths.doc = fullfile(obj.paths.project,'doc');
            obj.paths.matlab = fullfile(obj.paths.doc,'matlab');
            obj.paths.runData = char(strjoin(obj.paths.psfLocFolders(1:11),filesep));
%             obj.paths.testData = 
        end
        function getNetlist(obj)
            % Get netlist
            obj.paths.netlist = strsplit(obj.paths.psf,filesep);
            obj.paths.netlist = fullfile(char(strjoin(obj.paths.netlist(1:end-1),filesep)),'netlist', 'input.scs');
            obj.netlist = cdsOutMatlab.loadTextFile(obj.paths.netlist);
        end
        function getSpectreLog(obj)
        % Get Spectre log file
            obj.paths.spectreLog = fullfile(obj.paths.psf,'spectre.out');
            obj.info.log = cdsOutMatlab.loadTextFile(obj.paths.spectreLog);
        end
        function processCorner = getProcessCorner(obj)
        % Get the model information
            obj.paths.modelFileInfo = strsplit(obj.paths.psf,filesep);
            obj.paths.modelFileInfo = fullfile(char(strjoin(obj.paths.modelFileInfo(1:end-1),filesep)),'netlist', '.modelFiles');
            obj.info.modelFileInfo = cdsOutMatlab.loadTextFile(obj.paths.modelFileInfo);
            if(~isempty(obj.info.modelFileInfo) && (length(obj.info.modelFileInfo)==1))
                obj.processCorner = obj.info.modelFileInfo{1}(strfind(obj.info.modelFileInfo{1},'section=')+8:end);
            elseif(~isempty(obj.info.modelFileInfo))
                obj.processCorner = 'NOM';
            else
                obj.processCorner = '';
            end
            processCorner = obj.processCorner;
        end
        function getVariables(obj)
        % Gets the corner's variable data
        %
        % USE:
        %  obj.getVariables;
            obj.info.variables = cds_srr(obj.paths.psf,'variables');
            varNames = cds_srr(obj.paths.psf,'variables');
            varNames = varNames.variable;
            for i = 1:length(varNames)
                obj.info.variablesData.(regexprep(varNames{i}(1:end-6),'\(|\)|\.| ','')) = ...
                cds_srr(obj.paths.psf,'variables',varNames{i});
            end
            obj.variables = obj.info.variablesData;
        end
        function getDataSTB(obj)
        % Loads stability (stb) analysis data
            obj.analyses.stb.phaseMargin = cds_srr(obj.paths.psf,'stb-margin.stb','phaseMargin');
            obj.analyses.stb.gainMargin = cds_srr(obj.paths.psf,'stb-margin.stb','gainMargin');
            obj.analyses.stb.loopGain = cds_srr(obj.paths.psf,'stb-stb','loopGain');
            obj.analyses.stb.phaseMarginFrequency = cds_srr(obj.paths.psf,'stb-margin.stb','phaseMarginFreq');
            obj.analyses.stb.gainMarginFrequency = cds_srr(obj.paths.psf,'stb-margin.stb','gainMarginFreq');
            obj.analyses.stb.probe = cds_srr(obj.paths.psf,'stb-stb','probe');
            obj.analyses.stb.info = cds_srr(obj.paths.psf,'stb-stb');
            obj.analyses.stb.infoMargin = cds_srr(obj.paths.psf,'stb-margin.stb');
        end
        function getDataDC(obj)
            obj.analyses.dc.info = cds_srr(obj.paths.psf,'dc-dc');
            % Save transient waveforms
            if(~isempty(obj.analyses.dc.waveformsList))
                for wfmNum = 1:length(obj.analyses.dc.waveformsList)
                    obj.analyses.transient.(obj.analyses.dc.waveformsList{wfmNum}) = cds_srr(obj.paths.psf,'tran-tran',obj.analyses.transient.waveformsList{wfmNum});
                end
            end
        end
        function getDataDCop(obj)
            obj.analyses.dcOp.info = cds_srr(obj.paths.psf,'dcOp-dc');
        end
        function getDataTransient(obj)
            obj.analyses.transient.info = cds_srr(obj.paths.psf,'tran-tran');
            % Save transient waveforms
            if(~isempty(obj.analyses.dc.waveformsList))
                for wfmNum = 1:length(obj.analyses.transient.waveformsList)
                    obj.analyses.transient.(obj.analyses.transient.waveformsList{wfmNum}) = cds_srr(obj.paths.psf,'tran-tran',obj.analyses.transient.waveformsList{wfmNum});
                end
            end
        end
        function set.test(obj,val)
        % 
            if(~isa(val,'cdsOutTest'))
                error('VirtuosoToolbox:cdsOutCorner:set_test','test needs to be a cdsOutTest object')
            end
%             if(~strcmp(obj.names.test,val.name))
%                 error('VirtuosoToolbox:cdsOutCorner:set_test','test does not match the test of this corner')
%             end
            obj.test = val;
        end
    end
    methods (Static)
        function simNum = getSimNum(axlCurrentResultsPath)
        % getSimNum Provides the sin number for each corner.  This is 
        %  useful for saving each corner to a seperate cdsOutMatlab object
        %  and then returning to adexl by using the Results variable to show
        %  the correspondence between the adexl corner names and the sim
        %  number
        %
        % INPUTS
        %  axlCurrentResultsPath - Path to the psf folder containing the
        %   simulation results for a given corner.  This variable is
        %   provided in the workspace by adexl.
        % OUTPUTS
        %  simNum - Simulation number assigned that is assigned to each
        %   corner.
        % EXAMPLE
        %  Results = cdsOutMatlab.getSimNum(axlCurrentResultsPath);
        %  MAT(Results) = cdsOutMatlab.getSimNum(axlCurrentResultsPath);
        %  MAT.save(filePath)
        %
        % see also:
            psfLocFolders = strsplit(axlCurrentResultsPath,filesep);
            simNum = str2double(psfLocFolders{12});
        end
    end
end
