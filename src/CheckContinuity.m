function FEASIBLE = CheckContinuity(SS,PatchXYZ)

FEASIBLE = true;

% Reconstruct Stacking Sequences
NUniqueLam  = length(SS);
NPliesLam   = cellfun(@length,SS);
[NGuide,GuideIndex] = max(NPliesLam);
GuideAngles = num2cell(SS{GuideIndex});

for i = 1:NUniqueLam
    if i == GuideIndex || NPliesLam(i) == NGuide 
        SScell{i} = GuideAngles;    
    else 
        index = 1;
        for j=1:NGuide
            if index<=NPliesLam(i) && GuideAngles{j} == SS{i}(index)
                SScell{i}{j} = SS{i}(index);
                index = index +1;
            else
                SScell{i}{j} = [];
            end
        end
    end
end

% Number the edges 
NPatch      = length(PatchXYZ);
PatchEdgeId = zeros(NPatch,4); % save the Edge Id of each patch 
UniqueEdges = zeros(4*NPatch,6);

EdgeId = 1;
for iPatch = 1:NPatch
    
    if iPatch == 1
        
         for iEdge = 1:4
             if iEdge == 4
                UniqueEdges(EdgeId,:) =  [PatchXYZ{iPatch}.X(iEdge) PatchXYZ{iPatch}.Y(iEdge) PatchXYZ{iPatch}.Z(iEdge) PatchXYZ{iPatch}.X(1) PatchXYZ{iPatch}.Y(1) PatchXYZ{iPatch}.Z(1)];
             else
                UniqueEdges(EdgeId,:) =  [PatchXYZ{iPatch}.X(iEdge) PatchXYZ{iPatch}.Y(iEdge) PatchXYZ{iPatch}.Z(iEdge) PatchXYZ{iPatch}.X(iEdge+1) PatchXYZ{iPatch}.Y(iEdge+1) PatchXYZ{iPatch}.Z(iEdge+1)];
             end
            PatchEdgeId(iPatch,iEdge) =  iEdge; 
            EdgeId = EdgeId+1;
         end
        
    else
        
        for iEdge = 1:4
            if iEdge == 4
                Vertice =  [PatchXYZ{iPatch}.X(iEdge) PatchXYZ{iPatch}.Y(iEdge) PatchXYZ{iPatch}.Z(iEdge) PatchXYZ{iPatch}.X(1) PatchXYZ{iPatch}.Y(1) PatchXYZ{iPatch}.Z(1)];
            else
                Vertice =  [PatchXYZ{iPatch}.X(iEdge) PatchXYZ{iPatch}.Y(iEdge) PatchXYZ{iPatch}.Z(iEdge) PatchXYZ{iPatch}.X(iEdge+1) PatchXYZ{iPatch}.Y(iEdge+1) PatchXYZ{iPatch}.Z(iEdge+1)];
            end
            
            VerticeRevert = [Vertice(4:6) Vertice(1:3)];
            
            [Member1,MemberIndex1] = ismember(Vertice,UniqueEdges,'rows');
            [Member2,MemberIndex2] = ismember(VerticeRevert,UniqueEdges,'rows');
            
            if ~Member1 && ~Member2
                UniqueEdges(EdgeId,:) = Vertice;
                
                PatchEdgeId(iPatch,iEdge) =  EdgeId;
                EdgeId = EdgeId+1;
            else
                if Member1
                    PatchEdgeId(iPatch,iEdge) = MemberIndex1;
                else
                    PatchEdgeId(iPatch,iEdge) = MemberIndex2;
                end
            end
        end
        
    end
end
EdgeId = EdgeId -1;
UniqueEdges = UniqueEdges(1:EdgeId,:);


% Compute connection matrix between patches
NEdge             = length(PatchEdgeId(:));
PatchConnectivity = zeros(NPatch);
for iPatch = 1:NPatch
    for iEdge = 1:4
        [irow,~]=find(PatchEdgeId==PatchEdgeId(iPatch,iEdge));
        for j=1:length(irow)
            if irow(j)~=iPatch
                PatchConnectivity(iPatch,irow(j))=1;
            end
        end
    end
end

% figure
% hold all
% for iEdge= 1:EdgeId
%     % check geometry by plotting edges
%     plot3([UniqueEdges(iEdge,[1 4])],[UniqueEdges(iEdge,[2 5])],[UniqueEdges(iEdge,[3 6])])
% end

keyboard

% check the geometrical continuity of each ply
for iply = 1:NGuide
    
    CoveredPatch = find(~cellfun(@isempty, SScell)); % Patches which the ply is covering

    CoveredPatch(CoveredPatch == GuideIndex) = []; %#ok<NASGU>
    ConnectedPatch = find(PatchConnectivity(GuideIndex,:)); %#ok<EFIND>
    
    ContinuouSpan = GuideIndex;
    
    while ~isempty(ConnectedPatch)
        NewConnection = [];
        for j=1:length(ConnectedPatch)
            ContinuouSpan = [ContinuouSpan CoveredPatch(CoveredPatch==ConnectedPatch(j))];
            CoveredPatch(CoveredPatch==ConnectedPatch(j))=[];
            NewConnection = [NewConnection find(PatchConnectivity(ConnectedPatch(j),:))];
        end
        ConnectedPatch = unique(NewConnection);
        

        for j=1:length(ContinuouSpan)
            ConnectedPatch(ConnectedPatch == ContinuouSpan(j)) = []; % remove connection already accounted for
        end
    end
    
end

keyboard


end

