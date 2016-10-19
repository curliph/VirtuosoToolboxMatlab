classdef cdsOutMatlab < cdsOut
    %cdsOutMatlab A Cadence Matlab output script
    %   Creates a cadence MATLAB output script to handle the saving and
    %   analysis of Cadence simulation results using MATLAB
    %
    % See also: cdsOutMatlab/cdsOutMatlab, cdsOutMatlab/save,
    % cdsOutMatlab.load, cdsOutCorner, cdsOutRun,cdsOutTest
    
    
    properties
        results
        names
        paths
        runHistoryLength
    end
    properties (Transient = true)
        filepath
        currentRun
        currentTest
        currentCorner
        simDone
    end
    methods
        function obj = cdsOutMatlab(varargin)
        %cdsOutMatlab Creates a new matlab output saving script
            obj = obj@cdsOut(varargin{:}); % Superclass constructor
            if((nargin > 1) && ischar(varargin{1}))
                obj.paths.psfLocFolders = strsplit(varargin{1},filesep);
                if(isunix && isdir(varargin{1}))
                    obj.getNames(obj.paths.psfLocFolders);
                    obj.getPaths;              
                    obj.info.who = who;
                end
            end
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('axlCurrentResultsPath','',@(x) ischar(x) && isdir(x));
            p.addParameter('signals',[],@iscell);
            p.addParameter('transientSignals',[],@iscell);
            p.addParameter('dcSignals',[],@iscell);
            p.addParameter('filepath',[],@ischar);
            p.addParameter('runHistoryLength',10,@isdouble)
            p.parse(varargin{:});
            obj.filepath = p.Results.filepath;
            obj.runHistoryLength = p.Results.runHistoryLength;
            obj.results = cdsOutRun.empty;
            
            if(~isempty(p.Results.axlCurrentResultsPath))
                obj.currentCorner = cdsOutCorner(varargin{:});
                obj.addCorner(obj.currentCorner,varargin{2:end});
            end
            
        end
        function addCorner(obj,corner,varargin)
        	if(ischar(corner))
            % Initialize corner
            	corner = cdsOutCorner(corner);
            end
            if(~isa(corner,'cdsOutCorner'))
                error('VirtuosoToolbox:cdsOutTest:addCorner','corner must be a cdsOutCorner');
            end
            if(~isempty(obj.results))
                resultIdx = strcmp({obj.results.name},corner.names.result);
                resultNames = obj.results.names;
                libIdx = strcmp({resultNames.library},corner.names.library);
                if(~any(resultIdx & libIdx))
                    result = obj.addResult;
                elseif(sum(resultIdx & libIdx) == 1)
                    result = obj.results(resultIdx & libIdx);
                else
                    error('VirtuosoToolbox:cdsOutTest:addCorner','corner belongs to multiple results');
                end
            else
                result = obj.addResult;
            end
            result.addCorner(corner,varargin{:});
        end
        function result = addResult(obj,varargin)
%             if(ischar(resultIn))
%                 resultIn = cdsOutRun();
%             elseif(isa(resultIn,'cdsOutRun'))
%                 resultIn = 1;
%             end
%             resultIdx = strcmp(resultIn.name,{obj.results.name});
%             if(isempty(resultIdx))
            % Create new result
                if(length(obj.results) < obj.runHistoryLength)
                    result = cdsOutRun;
                    obj.results(end+1) = result;
                else
                    result = cdsOutRun;
                    obj.results = [obj.result(2:end-1) result];
                end
%             elseif(length(resultIdx) == 1)
            % Replace existing result
%                 obj.result(resultIdx) = resultIn;
%             else
%                 warning('VirtuosoToolbox:cdsOutMatlab:addResult','Duplicate results exist');
%             end
        end
        function save(obj,varargin)
        % Save Saves the cdsOutMatlab dataset to a file
        %   The dataset is saved to a file which contains a table named 
        %   data containing the data in a column and the library name, test
        %   bench cell name (TBcell), test name, and result name.
        % 
        %  Each dataset should only contain a single result
        %
        % USAGE
        %  data = MAT.save(filePath)
        % INPUTS
        %  filePath - file path to save the file. (optional) 
        %  If unspecified the dataset's current filePath is used.
        %  If specified the dataset's filepath property is set to filePath
        % OUTPUTS
        %  data - saved dataset table
        % see also: cdsOutMatlab
            p = inputParser;
            p.addOptional('filePath', [], @(x) ischar(x) || isempty(x));
            p.addParameter('saveMode','append',@ischar);
            p.parse(varargin{:});
            
            if(~isempty(p.Results.filePath))
                obj.filepath = p.Results.filePath;
                filePath = p.Results.filePath;
            elseif(~isempty({obj.filePath}))
                filePath = obj.filepath;
            else
                filePath = [];
            end
                        
            if(isempty(filePath) && ispc)
                [filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)'; ...
                	'*.*',  'All Files (*.*)'},'Select file to save data');
                if isequal(filename,0) || isequal(pathname,0)
                    disp('User pressed cancel')
                    return;
                else
                    obj.filepath = fullfile(pathname,filename);
                end
            end
            % Append to an existing file
%             obj(1).filepath
            
            % Save
            % MAT.Project.testBenchCell.Test = obj
%             library = unique(arrayfun(@(x) x.names.library,obj,'UniformOutput',false));
%             TBcell = unique(arrayfun(@(x) x.names.testBenchCell,obj,'UniformOutput',false));
%             test = unique(arrayfun(@(x) x.names.test,obj,'UniformOutput',false));
%             result = unique(arrayfun(@(x) x.names.result,obj,'UniformOutput',false));
%             result = regexprep(result,'\(|\)|\.| ','_');
%             data = table(obj,library,TBcell,test,result);
%             data.Properties.VariableNames = {'data','library','TBcell','test','result'};
%             MAT.(char(library)).(char(TBcell)).(char(test)).(char(result)) = obj;
            save(obj.filepath,'obj');
%             save(obj(1).filepath,'MAT');
        end
        function val = get.names(obj)
            if(~isempty(obj.results))
                val = obj.names;
%                 val.lol = unique({obj.runs})
            else
                val = struct;
            end
        end
        function val = get.simDone(obj)
            if(isempty(obj.results))
                val = false;
            else
                % Check to make sure all the runs are complete
                val = all([obj.results.simDone]);
            end
        end
        function getPaths(obj)
            obj.paths.project = char(strjoin({'','prj',obj.names.project},filesep));
            obj.paths.doc = fullfile(obj.paths.project,'doc');
            obj.paths.matlab = fullfile(obj.paths.doc,'matlab');
            obj.paths.runData = char(strjoin(obj.paths.psfLocFolders(1:11),filesep));
%             obj.paths.testData = 
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
            try
                psfLocFolders = strsplit(char(axlCurrentResultsPath),filesep);
                simNum = str2double(psfLocFolders{12});
            catch ME
                simNum = -1;
                disp(ME)
            end
        end
        function data = load(varargin)
        %load Loads a saved datafile
        %
        % USAGE
        %  data = cdsOutMatlab.load(filePath);
        %
        % see also: cdsOutMatlab/save
        % USAGE
        %  data = cdsOutMatlab.load(filePath);
        % INPUTS
        %  filePath - a single file path or a cell array of paths to load
        % Outputs
        %  data - dataset table containing the following columns: data, 
        %   library name, test bench cell name (TBcell), test name, and 
        %   result name.
        %
        % see also: cdsOutMatlab/save
            p = inputParser;
            p.addOptional('filepath',[],@(x) ischar(x) || iscell(x));
%             p.addParameter('tableOut',false,@islogical);
            p.parse(varargin{:});
            if(isempty(p.Results.filepath))
                [filename, pathname] = uigetfile({'*.mat','MAT-files (*.mat)'; ...
                	'*.*',  'All Files (*.*)'},'Select file to save data',...
                    'MultiSelect', 'on');
                if isequal(filename,0) || isequal(pathname,0)
                    disp('User pressed cancel')
                    return;
                else
                    if(iscell(filename))
                        cellfun(@(x,y) fullfile(x,y),pathname,filename);
                    else
                        filePath = fullfile(pathname,filename);
                    end
                end
            else
                filePath = p.Results.filepath;
            end
            if(ischar(filePath))
                data = load(filePath);
                data = data.obj;
            elseif(iscell(filePath))
                data = cdsOutMatlab.empty;
                for fileIdx = 1:length(filePath)
                    dataIn = load(filePath{fileIdx});
                    data = [data dataIn.obj];
                end
            else
                data = cdsOutMatlab.empty;
            end
%             library = {};
%             result = {};
%             cell = {};
%             test = {};
%             libs = fieldnames(MAT);
%             for libIdx = 1:length(libs)
%                 testBenches = fieldnames(MAT.(libs{libIdx}));
%                 for testBenchIdx = 1:length(testBenches)
%                     tests = fieldnames(MAT.(libs{libIdx}).(testBenches{testBenchIdx}));
%                     for testIdx = 1:length(tests)
%                         res = fieldnames(MAT.(libs{libIdx}).(testBenches{testBenchIdx}).(tests{testIdx}));
%                         [result{end+1:end+length(res)}] = deal(char(res));
%                         [library{end+1:end+length(res)}] = deal(char(libs{libIdx}));
%                         [cell{end+1:end+length(res)}] = deal(char(testBenches{testBenchIdx}));
%                         [test{end+1:end+length(res)}] = deal(char(tests{testIdx}));
%                         data = struct2cell(MAT.(libs{libIdx}).(testBenches{testBenchIdx}).(test{testIdx}));
%                         data = [data{:}];
%                     end
%                 end
%             end
%             switch nargout
%                 case {0,1}
%                     if(p.Results.tableOut)
%                         varargout = {table(data, library', cell', test', result')};
%                         varargout{1}.Properties.VariableNames = {'data', 'library', 'cell', 'test', 'result'};
%                     else
%                         varargout = {data};
%                     end
%                 case 2
%                     varargout = {data result};
%                 case 3
%                     varargout = {data test result};
%                 case 4
%                     varargout = {data cell test result};
%                 case 5
%                     varargout = {data library cell test result};
%                 otherwise
%                     error('skyVer:cdsOutMatlab:load','Wrong number of outputs');
%             end
        end
        function loadData(varargin)
        % loadData Loads data from the Cadence database using MATLAB
        %  
        % 
%         =dir(varargin{1})
%         
%             for cornerNum = 1:length()
%                 
%             end
        end
    end
end

