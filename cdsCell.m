classdef cdsCell < matlab.mixin.SetGet
    %cdsCell A Cadence cell
    %   Basic cell information
    %
    % USAGE
    %  cell = cdsCell(name,...)
    % INPUTS and PROPERTIES
    %  Name - cellname [char]
    % PARAMETERS and PROPERTIES
    %  Library - library name or cdsLibrary object [cdsLibrary or char]
    %  Pinout - skyPinout object representing the pinout of the cell.
    %   [skyPinout]
    % see also: cdsLibrary
    
    properties
        Library cdsLibrary
        Pinout skyPinout
    end
    properties (Access = protected)
        Name
    end
    methods
        function obj = cdsCell(name,varargin)
        %bandgap Construct a new cdsCell cell object
        %   See class description for usage information
        %
        % See also: cdsCell
            p = inputParser;
            p.KeepUnmatched = true;
            p.addRequired('Name',@ischar);
            p.addParameter('Library',cdsLibrary.empty,@(x) ischar(x) || isa(x,'cdsLibrary'));
            p.addParameter('Pinout',skyPinout.empty,@(x) isa(x,'skyPinout') || ischar(x));
            p.parse(name,varargin{:});
            
            obj.Name    = p.Results.Name;
            if(ischar(p.Results.Pinout))
                obj.Pinout  = skyPinout(p.Results.Pinout);
            else
                obj.Pinout  = p.Results.Pinout;
            end
            obj.Library = p.Results.Library;
        end
        function set.Name(obj,val)
            if(~ischar(val))
                error('VirtuosoToolbox:cdsCell:notChar','name must be a char')
            end
            obj.Name = val;
        end
        function set.Library(obj,val)
            if(ischar(val))
                val = cdsLibrary(val);
            end
            obj.Library = val;
        end
    end
    
end

