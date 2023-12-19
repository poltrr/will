using { /UnrealEngine.com/Temporary/SpatialMath }
using { MinHeapByPoltrr }

AStarByPoltrr<public> := module:
    # Classes #
    
    # Base comparable node.
    node<public>(t : type) := class<abstract><unique>:
        Translation<public> : t
        GetNeighbors<public>()<transacts> : []node(t)
    
    # Comporable `vector2` node.
    node2<public> := class<abstract>(node(vector2)) {}

    # Comparable `vector3` node.
    node3<public> := class<abstract>(node(vector3)) {}

    # Implementation of a* data class for `node3`.
    # Remove when mutable members in parametric classes are implemented.
    node3_data<internal> := class<unique>(comparable_type):
        # Attributes #
        
        # Node owner.
        Node<public> : node3

        # Heuristic estimate of the cost to the end node.
        H<public> : float
        
        # Cost of the path to the start node.
        var MaybeG<private> : ?float = false

        # Previous node in the path.
        var MaybePrevious<private> : ?node3_data = false

        # Methods #

        # Succeeds if lesser than `Compare`.
        IsLessThan<override>(Compare : comparable_type)<transacts><decides> : void =
            CompareData := node3_data[Compare]
            GetF[] < CompareData.GetF[] or
            GetF[] = CompareData.GetF[] and H < CompareData.H
        
        # Succeeds if greater than `Compare`.
        IsGreaterThan<override>(Compare : comparable_type)<transacts><decides> : void =
            CompareData := node3_data[Compare]
            GetF[] > CompareData.GetF[] or
            GetF[] = CompareData.GetF[] and H > CompareData.H

        GetG<public>()<transacts><decides> : float = MaybeG?

        GetF<public>()<transacts><decides> : float = MaybeG? + H

        GetPrevious<public>()<transacts><decides> : node3_data = MaybePrevious?
        
        SetG<public>(G : float)<transacts> : void =
            set MaybeG = option{G}
        
        SetPrevious<public>(Previous : node3_data)<transacts> : void =
            set MaybePrevious = option{Previous}
    
    # Implementation of `node3_data` constructor.
    # Remove when `node3_data` is removed.
    MakeNode3Data<constructor>(Node : node3, EndNode : node3)<transacts> := node3_data:
        Node := Node
        H := Distance(Node.Translation, EndNode.Translation)
    
    # A* implementation.
    a_star<public> := class<final>:
        # Return the shortest path from `Start` to `End`. Not yet implemented.
        GetShortestPath<public>(Start : node(t), End : node(t) where t : type)<transacts><decides> : []node(t) =
            array{}

        # Return the shortest `node3` path of from `Start` to `End`.
        # Remove when a parametic min_heap class is implemented.
        GetShortestPathNode3<public>(Start : node3, End : node3)<transacts><decides> : []node3 =
            # Priority queue of nodes-to-search data.
            ToSearch := min_heap_comparable_type{}
            # Map node to its data.
            var Nodes : [node3]node3_data = map{}
            # Set of processed-nodes data.
            var Processed : [node3_data]logic = map{}
            # Node data path from `Start` to `End`.
            var MaybeBackwardsPathData : ?[]node3_data = false

            # Create node data for `Start` node.
            StartData := MakeNode3Data(Start, End)
            StartData.SetG(0.0)
            # Add origin node data.
            ToSearch.Push[StartData]
            # Map `Start` to its node data.
            set Nodes[Start] = StartData

            # Search for a path.
            loop:
                # `End` hasn't been reached, and there are still unsearched-nodes.
                if:
                    CurrentData : node3_data = node3_data[ToSearch.Top[]]
                    ToSearch.Pop[]
                    set Processed[CurrentData] = true
                    CurrentNode : node3 = CurrentData.Node
                then:
                    # Store backwards path if `End` is reached.
                    if (CurrentNode = End):
                        var CurrentPathData : node3_data = CurrentData
                        var BackwardsPathData : []node3_data = array{CurrentPathData}
                        # Navigate from `End` to `Start` in the path, and store the path.
                        loop:
                            # `Start` hasn't been reached.
                            if:
                                PreviousPathData : node3_data = CurrentPathData.GetPrevious[]
                                not PreviousPathData = Start
                            then:
                                set BackwardsPathData += array{PreviousPathData}
                                set CurrentPathData = PreviousPathData
                            # `Start` was reached.
                            else:
                                set MaybeBackwardsPathData = option{BackwardsPathData}
                                break
                            # Path found. Stop searching for path.
                        break
                    
                    for:
                        Neighbor : CurrentNode.GetNeighbors()
                        NeighborNode := node3[Neighbor]
                        # Get `NeighborNode` node data, or create one if non exists.
                        NeighborData : node3_data = 
                            if (Data : node3_data = Nodes[NeighborNode]) 
                            then Data 
                            else MakeNode3Data(NeighborNode, End)
                        # Skip processed nodes.
                        not Processed[NeighborData]
                        # Calculate new G cost from current node.
                        NewG := CurrentData.GetG[] + Distance(CurrentNode.Translation, NeighborNode.Translation)
                        # Filter for nodes with higher G cost.
                        # New nodes with new node data will also succeed.
                        not NeighborData.GetG[] >= NewG
                    do:
                        # Update `NeighborData` G cost and previous node.
                        NeighborData.SetG(NewG)
                        NeighborData.SetPrevious(CurrentData)
                        # Map `NeighborData` to its node, and add to `ToSearch`.
                        # Skip if already stored.
                        if:
                            not Nodes[NeighborNode]
                            set Nodes[NeighborNode] = NeighborData
                            ToSearch.Push[NeighborData]
                else:
                    break
            
            # Reverse the order of the path.
            LastIndex : int = MaybeBackwardsPathData?.Length - 1
            for (Index := 0..LastIndex):
                MaybeBackwardsPathData?[LastIndex - Index].Node
