classdef cdsOutTest < cdsOut
    %cdsOutRun Cadence Simulation run results
    %   Collects the data from a single Cadence simulation run.
    
    properties
        corners % An array of cdsOutCorners arranged by simNum
        cornernames
        run
        names
        paths
    end
    properties (Transient)
        cornerDoneCnt
    end
    properties (Dependent)
        simDone
    end
        
    methods
        function obj = cdsOutTest(varargin)
        % create a new cdsOutCorner object
        %
        % USE
        %  obj = cdsOutCorners(run, corner ...)
        %
        % INPUTS
        %  run - Cadence run for this test [cdsOutRun](optional)
        %  corner - First corner for this test [cdsOutCorner](optional)
        % PARAMETERS
        %  signals - defines the signals to save
        %  transientSignals - defines the signals to save only for a
        %   transient analysis
        %  dcSignals - defines the signals to save only for a
        %   dc analysis
        %  desktop - Opens a new desktop if one isn't open yet (logical)
        %
        % See also: cdsOutCorner, cdsOutTest, cdsOutRun
        
%             obj@cdsOut(
%             if(isa(varargin{1},'cdsOutCorner'))
%                 if(isa(varargin{1},'cdsOutRun'))
%                     if(nargin>2)
%                         obj = obj@cdsOut(varargin{3:end}); % Superclass constructor
%                     else
%                         obj = obj@cdsOut; % Superclass constructor
%                     end
%                 elseif(nargin>1)
%                     obj = obj@cdsOut(varargin{2:end}); % Superclass constructor
%                 else
%                     
%                 end
%             else
%                 obj = obj@cdsOut(varargin{:}); % Superclass constructor
%             end
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('corner',cdsOutCorner.empty,@(x) isa(x,'cdsOutCorner'));
            p.addOptional('run',cdsOutRun.empty,@(x) isa(x,'cdsOutRun'));
            p.parse(varargin{:});
            obj.cornerDoneCnt = 0;
            
            % Add first corner
            obj.corners = cdsOutCorner.empty;
            obj.addCorner(p.Results.corner);
            obj.getCornerList;
        end
        function set.corners(obj,val)
%             if(~isempty(val))
% %                 if(~strcmp(obj.name, val.names.test))
% %                 % Check that this corner is for this test
% %                     error('VirtuosoToolbox:cdsOutTest:setCorners','Wrong test name');
% %                 end
%                 val.test = obj;
%             end
            if(~isa(val,'cdsOutCorner'))
                error('VirtuosoToolbox:cdsOutTest:addCorner','corner must be a cdsOutCorner');
            end
            obj.corners = val;
            if(exist('obj.info.corner','var') && isempty(obj.info.corner))
                obj.getCornerList;
            end
        end
        function addCorner(obj,corner)
            if(ischar(corner))
            % Initialize corner
                corner = cdsOutCorner(corner);
            end
            if(~isa(corner,'cdsOutCorner'))
                error('VirtuosoToolbox:cdsOutTest:addCorner','corner must be a cdsOutCorner');
            end
            if(isempty(obj.corners) && ~isempty(corner))
            % initialize test with the properties of the given corner
                obj.name = corner.names.test;
                obj.names.result = corner.names.result;
                obj.names.library = corner.names.library;
                corner.test = obj;
            elseif(~isempty(obj.corners) && ~isempty(corner))
                if(~strcmp(obj.name, corner.names.test))
                % Check that this corner is for this test
                    error('VirtuosoToolbox:cdsOutTest:setCorners','Wrong test name');
                end
            end
            obj.corners(corner.simNum) = corner;
            obj.names = corner.names;
            obj.paths = corner.paths;
            obj.cornerDoneCnt = obj.cornerDoneCnt +1;
        end
        function getAllPropertiesCorners(obj)
        % Corners psf properties
            obj.info.corners.tranDatasets = cds_srr(obj.paths.psfPathCorners,'tran-tran');
            cornerProperties = obj.info.corners.tranDatasets.prop;
            for i = 1:length(cornerProperties)
                obj.info.corners.properties.(regexprep(cornerProperties{i},'\(|\)|\.| ','')) = ...
                cds_srr(obj.paths.psfPathCorners,'tran-tran',cornerProperties{i});
            end
        end
        function getCornerList(obj)
        % Corner Info
            if(~isempty(obj.corners))
                obj.paths.psfPathCorners = strjoin([obj.paths.psfLocFolders(1:11) 'psf' obj.paths.psfLocFolders(13) 'psf'],filesep);
                obj.paths.run = strjoin(obj.paths.psfLocFolders(1:11),filesep);
                obj.paths.psfTmp = strjoin([obj.paths.psfLocFolders(1:10) ['.tmpADEDir_' obj.names.user] obj.names.test [obj.names.library '_' obj.names.testBenchCell '_schematic_spectre'] 'psf'],filesep);
                obj.paths.runObjFile = strjoin({obj.paths.psfTmp 'runObjFile'},filesep);
                obj.info.runObjFile = cdsOutMatlab.loadTextFile(obj.paths.runObjFile);
                numCornerLineNum = strncmp('"Corner_num"',obj.info.runObjFile,12);
                obj.info.numCorners = str2double(obj.info.runObjFile{numCornerLineNum}(13:end));
                corners = {obj.info.runObjFile{find(numCornerLineNum)+1:find(numCornerLineNum)+obj.info.numCorners}};
                obj.info.cornerNames = cellfun(@(x,y) x(y(3)+1:end-1),corners,strfind(corners,'"'),'UniformOutput',false);
%                 obj.names.corner = obj.info.cornerNames{obj.simNum};
%                 obj.getCornerInfo;
            end
        end
        function val = get.simDone(obj)
            if(isstruct(obj.info) && isfield(obj.info,'numCorners'))
                val = (obj.cornerDoneCnt == obj.info.numCorners);
            else
                val = false;
            end
        end
    end
    
end
