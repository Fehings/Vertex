function [NeuronModel, SynModel, InModel] = ...
  groupUpdateSchedule(NP,SS,NeuronModel,SynModel,InModel,iGroup, StimParams,simStep)


% update synaptic conductances/currents according to buffers
for iSyn = 1:size(SynModel, 2)
  if ~isempty(SynModel{iGroup, iSyn})
    updateBuffer(SynModel{iGroup, iSyn});
    updateSynapses(SynModel{iGroup, iSyn}, NeuronModel{iGroup}, SS.timeStep);
  end
end

% update axial currents
if NP(iGroup).numCompartments > 1
  updateI_ax(NeuronModel{iGroup}, NP(iGroup));
end

% update inputs
if ~isempty(InModel)
    for iIn = 1:size(InModel, 2)
        if ~isempty(InModel{iGroup, iIn})
            %if it is an electric field input pass it the electric field
            %effect at each compartment
            if isa(InModel{iGroup, iIn}, 'InputModel_i_efield')
                updateInput(InModel{iGroup, iIn},NeuronModel{iGroup}, StimParams.activation{iGroup});
            %if it is an focused ultrasound input pass it the effect/field strength at
            %each compartment. If during this function fusBLS is called
            %then I also need to pass in the capacitance, membrane
            %potentials and the parameters which need to be initialised
            %outside of this loop.
            elseif isa(InModel{iGroup, iIn}, 'InputModel_i_focusedultrasound')
                %find parameters for ultrasound and calculate capacitance
                updateCapacitance(InModel{iGroup, iIn},NeuronModel{iGroup}, StimParams.ultrasound{iGroup},simStep);
                %update the main capacitance values
                NP(iGroup).C=InModel{iGroup,iIn}.fusParams.C;
                %unique(StimParams.FusParams(iGroup).fusparams.C)
                %unique(NP(iGroup).C)% check that this is actually updating each turn as it should...
                %Now upate the input, which is the dCmVm value calculates in updateCapacitance 
                updateInput(InModel{iGroup, iIn});%,StimParams.FusParams(iGroup).fusparams);
                
            else
                updateInput(InModel{iGroup, iIn},NeuronModel{iGroup});    
            end
        end
    end
end


% update neuron model variables
if ~isempty(InModel)

  updateNeurons(NeuronModel{iGroup}, InModel(iGroup, :), ...
                NP(iGroup), SynModel(iGroup, :), SS.timeStep);
else
  updateNeurons(NeuronModel{iGroup}, [], ...
                NP(iGroup), SynModel(iGroup, :), SS.timeStep);
end