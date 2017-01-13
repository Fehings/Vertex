function [ v_m ] = getExtracellularInput(TP, StimParams, t, NeuronModel, NeuronParams)
%Returns a matrix representing the potential change at each compartment
%given the PDE solution and locations of the compartments. Uses the
%activation function.
 
if isa(TP.StimulationField, 'pde.StationaryResults')
    F = TP.StimulationField;
elseif isa(TP.StimulationField, 'pde.TimeDependentResults')
    F = TP.StimulationField;
else
    F = pdeInterpolant(TP.StimulationField{1},TP.StimulationField{2},TP.StimulationField{3});
end
 
 
activation = cell(TP.numGroups,1);
func = 'mirror';
 
for iGroup = 1:TP.numGroups
    point1 = StimParams.compartmentlocations{iGroup,1};
    point2 = StimParams.compartmentlocations{iGroup,2};
  
    midpoint = zeros(3,length(point1.x(:,1)),length(point1.x(1,:)));
    midpoint(1,:,:) = (point1.x + point2.x)./2;
    midpoint(2,:,:) = (point1.y + point2.y)./2;
    midpoint(3,:,:) = (point1.z + point2.z)./2;
%     
%     
%     max(max(max(midpoint<=0)))
%     max(max(point1.x<=0))
%     max(max(point1.y<=0))
%     max(max(point1.z<=0))
%     max(max(point2.x<=0))
%     max(max(point2.y<=0))
%     max(max(point2.z<=0))
% 
%     error()
     numcompartments = length(point1.x(:,1));
    if strcmp(func,'mirror')
        [l,d] = getDimensionsInCentimetres(NeuronParams(iGroup));
        g =  NeuronParams(iGroup).g_l /10^9; %from picoSeimens to Seimens
 
        for iC = 1:numcompartments
            a = squeeze(midpoint(:,iC,:));
            if isa(TP.StimulationField, 'pde.TimeDependentResults')
                v_ext(:,:,iC) = interpolateSolution(F,a,t);
            else
                v_ext(:,iC) = interpolateSolution(F,a);
            end
            if sum(isnan(v_ext(:,iC)))>0
                disp('Warning: Found nans in the extracellular field. Setting them to zero.')
                v_ext(isnan(v_ext(:,iC)), iC) = 0; 
            end
        end
        for iN = 1:length(midpoint(1,1,:))
            if isa(TP.StimulationField, 'pde.TimeDependentResults')
                for ii = 1:size(v_ext,2) % step through time dimension
                    neuronmean(iN,ii) = sum((g .* d .* mean(v_ext(iN,ii,:),3)))./sum(g .* d);
                end
            else
                neuronmean(iN) = sum((g .* d .* mean(v_ext(iN,:))))./sum(g .* d);
            end
        end
        neuronmean = neuronmean';
    end
    for iComp = 1:numcompartments
        if strcmp(func,'activation')
        v_m{iGroup}(iComp,:) = activationfunction([point1.x(iComp,:);point1.z(iComp,:);point1.y(iComp,:)] ,...
            [point2.x(iComp,:); point2.z(iComp,:);point2.y(iComp,:)],...
           F,t);
        elseif strcmp(func,'cable')
            %Get neighbours
        v_m{iGroup}(iComp,:) = get_extracellular_current([point1.x(iComp,:);point1.z(iComp,:);point1.y(iComp,:)] ,...
            [point2.x(iComp,:); point2.z(iComp,:);point2.y(iComp,:)],...
           F,t, NeuronModel, NeuronParams,neighbour1,neighbour2,neighbour3);
        elseif strcmp(func,'mirror')
            if isa(TP.StimulationField, 'pde.TimeDependentResults')
               for ii = 1:size(v_ext,2) % step through time
                   v_m{iGroup}(iComp,:,ii) = - v_ext(:,ii,iComp) + neuronmean(ii);
               end
            else
                v_m{iGroup}(iComp,:) = - v_ext(:, iComp) + neuronmean;
            end
        end
    end
    clear v_ext;
    clear neuronmean;
end
 
end
 
% convert user provided lengths and diameters from microns to cm
 
function [l, d] = getDimensionsInCentimetres(NP)
l = NP.compartmentLengthArr .* 10^-4;
d = NP.compartmentDiameterArr .* 10^-4;
end