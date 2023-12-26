using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }
using { AStarByPoltrr }

NavigationMeshSystemByPoltrr<public> := module:
    # Structs #

    edge<public> := struct:
        # Indexes of the left and right vertices, from the center of the triangle.
        Left<public> : int
        Right<public> : int
    
    step<public> := struct:
        Translation<public> : vector3
        Triangle<public> : triangle
    
    # Classes #

    # Debug draw channel.
    dd_channel<internal> := class(debug_draw_channel) {}
    
    triangle<public> := class(node3):
        # Attributes #

        # Indexes of vertices A B C.
        A<public> : int
        B<public> : int
        C<public> : int

        # Neighboring triangles mapped to the edge they share.
        var Neighbors<private> : [triangle]edge = map{}
        
        # Methods #

        GetNeighbors<override>()<transacts> : []triangle =
            for (Neighbor -> EdgeIndex : Neighbors):
                Neighbor
        
        GetEdge<public>(Neighbor : triangle)<transacts><decides> : edge = Neighbors[Neighbor]
        
        SetNeighbors<public>(InNeighbors : [triangle]edge)<transacts> : void =
            set Neighbors = InNeighbors
    
    navmesh<public> := class:
        # Attributes #

        # A* star implementation.
        AStar<private> : a_star = a_star{}
        
        # List of all vertices in the mesh.
        var Vertices<public> : []vector3

        # List of all triangles in the mesh.
        var Triangles<public> : []triangle

        # Vertical area, in meters, that the navmesh covers.
        Height<public> : float = 1.5

        # Methods #

        # Succeeds if `Point` is inside `Triangle`.
        IsPointInsideTriangle<public>(Triangle : triangle, Point : vector3)<transacts><decides>: void =
            # Vertices of triangle.
            A := Vertices[Triangle.A]
            B := Vertices[Triangle.B]
            C := Vertices[Triangle.C]

            V0 := C - A
            V1 := B - A
            V2 := Point - A

            Dot00 := DotProduct(V0, V0)
            Dot01 := DotProduct(V0, V1)
            Dot02 := DotProduct(V0, V2)
            Dot11 := DotProduct(V1, V1)
            Dot12 := DotProduct(V1, V2)

            InvDenom := 1.0 / (Dot00 * Dot11 - Dot01 * Dot01)

            U := (Dot11 * Dot02 - Dot01 * Dot12) * InvDenom
            V := (Dot00 * Dot12 - Dot01 * Dot02) * InvDenom

            U >= 0.0 and V >= 0.0 and U + V <= 1.0
        
        # Return closest point on line `AB` from `Point`.
        # Fails if no closest point exists.
        GetClosestPointOnLineSegment<public>(A : vector3, B : vector3, Point : vector3)<transacts><decides>: vector3 =
            Direction := B - A
            Magnitude := Direction.Length()
            NormalizedDirection := Direction.MakeUnitVector[]

            V := Point - A
            T := DotProduct(V, NormalizedDirection)

            # Calculate closest point.
            if (T <= 0.0):
                A
            else if (T >= Magnitude):
                B
            else:
                A + NormalizedDirection * T
        
        # Return closest point on `Triangle` from `Point`.
        GetClosestPointOnTriangle<public>(Triangle : triangle, Point : vector3)<transacts><decides> : vector3 =
            # Vertices of triangle.
            A := Vertices[Triangle.A]
            B := Vertices[Triangle.B]
            C := Vertices[Triangle.C]

            Normal := CrossProduct(B - A, C - A).MakeUnitVector[]
            AP := Point - A
            Dist := DotProduct(AP, Normal)

            ClosestPoint := Point - Normal * Dist

            if (IsPointInsideTriangle[Triangle, ClosestPoint]):
                ClosestPoint
            else:
                ClosestPointPerEdge := array:
                    GetClosestPointOnLineSegment[A, B, Point]
                    GetClosestPointOnLineSegment[B, C, Point]
                    GetClosestPointOnLineSegment[C, A, Point]
                
                var ClosestPointOnEdge : tuple(vector3, float) = (vector3{}, Inf)

                for (EdgePoint : ClosestPointPerEdge):
                    DistanceToEdge := Distance(Point, EdgePoint)
                    if (DistanceToEdge < ClosestPointOnEdge(1)):
                        set ClosestPointOnEdge = (EdgePoint, DistanceToEdge)
                
                ClosestPointOnEdge(0)
        
        # Return closest triangle in the mesh to `Point`, within `MaxCentimeters` range.
        # Fail if no such triangle exists inside the mesh or within range.
        GetClosestTriangleToPoint<public>(Point : vector3, ?MaxMeters : float = Height)<transacts><decides> : triangle =
            var ClosestTriangle : tuple(?triangle, float) = (false, Inf)
            
            # Loop through `Triangles` and store each shortest distance to `Point`.
            for (Triangle : Triangles):
                ClosestPoint := GetClosestPointOnTriangle[Triangle, Point]
                ShortestDistance := Distance(Point, ClosestPoint)
                if (ShortestDistance < (MaxMeters * 100.0); ShortestDistance < ClosestTriangle(1)):
                    set ClosestTriangle = (option{Triangle}, ShortestDistance)
            
            # Return closest triangle found, if any.
            ClosestTriangle(0)?
        
        # Return the shortest path of triangles between `From` and `To`.
        GetShortestPath<public>(From : triangle, To : triangle)<transacts><decides> : []triangle =
            for (Node3 : AStar.GetShortestPathNode3[From, To]):
                triangle[Node3]
        
        # Return the shortest path of points between `From` and `To`.
        GetShortestSmoothPath<public>(From : triangle, To : triangle)<transacts><decides> : []vector3 =
            for (Triangle : GetShortestPath[From, To]):
                Triangle.Translation
        
        # Return the first step in a smooth path from `A` to `B`. Requires an non-smooth `Path`.
        GetFirstSmoothStep<public>(Path : []triangle, A : vector3, B : vector3)<transacts><decides> : step =
            # The resulting step.
            var Step : step = step{Translation := B, Triangle := Path[Path.Length - 1]}
            
            if (TrianglesToVisit : []triangle = Path.Slice[1]; TrianglesToVisit.Length > 0):
                
                # Origin point of the funnel.
                Origin : vector3 = A
                
                # First edge encountered in the path.
                FirstEdge : edge = Path[0].GetEdge[Path[1]]
                
                # Current index of the left vertex of the funnel.
                var Left : int = FirstEdge.Left

                # Current index of the right vertex of the funnel.
                var Right : int = FirstEdge.Right

                # Current angle of the funnel.
                var Angle : float = MakeShortestRotationBetween(Vertices[Left] - A, Vertices[Right] - A).GetAngle()

                # Skip triangles if the first angle is 0.0, i.e. if `A` is on top of the first edge from the path.
                if (Angle.IsAlmostZero[0.0]):
                    set Step = GetFirstSmoothStep[TrianglesToVisit, A, B]
                else:
                    # Loop used as a work-around to break out of the for-loop.
                    loop:
                        for (Index -> Triangle : TrianglesToVisit):
                            if:
                                NextTriangle := TrianglesToVisit[Index + 1]
                                Edge := Triangle.GetEdge[NextTriangle]
                                NextLeftVertex := Vertices[Edge.Left]
                                NextRightVertex := Vertices[Edge.Right]
                            then:
                                # Try to tighten the left funnel.
                                if:
                                    Edge.Left <> Left
                                    RightVertex := Vertices[Right]
                                    FunnelRight := RightVertex - Origin
                                then:
                                    FunnelLeft := NextLeftVertex - Origin
                                    FunnelLeftXY := vector3{X := FunnelLeft.X; Y := FunnelLeft.Y}
                                    FunnelRightXY := vector3{X := FunnelRight.X; Y := FunnelRight.Y}

                                    # Left crosses over. Reached the first smooth step in the path.
                                    if (CrossProduct(FunnelLeftXY, FunnelRightXY).Z <= 0.0):
                                        set Step = step{Translation := RightVertex; Triangle := Triangle}
                                        break
                                    
                                    NewAngle := MakeShortestRotationBetween(FunnelLeftXY, FunnelRightXY).GetAngle()

                                    # Change the left funnel, if the funnel was tightened.
                                    if (NewAngle < Angle):
                                        set Angle = NewAngle
                                        set Left = Edge.Left
                                
                                # Try to tighten the right funnel.
                                if:
                                    Edge.Right <> Right
                                    LeftVertex := Vertices[Left]
                                    FunnelLeft := LeftVertex - Origin
                                then:
                                    FunnelRight := NextRightVertex - Origin
                                    FunnelLeftXY := vector3{X := FunnelLeft.X; Y := FunnelLeft.Y}
                                    FunnelRightXY := vector3{X := FunnelRight.X; Y := FunnelRight.Y}

                                    # Right crosses over. Reached the first smooth step in the path.
                                    if (CrossProduct(FunnelLeftXY, FunnelRightXY).Z <= 0.0):
                                        set Step = step{Translation := LeftVertex; Triangle := Triangle}
                                        break
                                    
                                    NewAngle := MakeShortestRotationBetween(FunnelLeftXY, FunnelRightXY).GetAngle()

                                    # Change the right funnel, if the funnel was tightened.
                                    if (NewAngle < Angle):
                                        set Angle = NewAngle
                                        set Right = Edge.Right
                            else:
                                NextVertex := B

                                if:
                                    RightVertex := Vertices[Right]
                                    LeftVertex := Vertices[Left]
                                    FunnelRight := RightVertex - Origin
                                then:
                                    FunnelLeft := NextVertex - Origin
                                    FunnelLeftXY := vector3{X := FunnelLeft.X; Y := FunnelLeft.Y}
                                    FunnelRightXY := vector3{X := FunnelRight.X; Y := FunnelRight.Y}

                                    # Left crosses over. Reached the first smooth step in the path.
                                    if (CrossProduct(FunnelLeftXY, FunnelRightXY).Z <= 0.0):
                                        set Step = step{Translation := RightVertex; Triangle := Triangle}
                                        break
                                    
                                    NewAngle := MakeShortestRotationBetween(FunnelLeftXY, FunnelRightXY).GetAngle()

                                    # End point `B` reached. First smooth step reached the end.
                                    if (NewAngle < Angle) then break
                                    
                                    # Right crosses over. Reached the first smooth step in the path.
                                    set Step = step{Translation := LeftVertex; Triangle := Triangle}
                        break
            
            # Return a projected step to its triangle.
            step:
                Translation := vector3:
                    X := Step.Translation.X
                    Y := Step.Translation.Y
                    Z := GetClosestPointOnTriangle[Step.Triangle, Step.Translation].Z
                Triangle := Step.Triangle
        
        ApplyScaleAndOffset<public>(?Scale : type{t : float where t > 0.0} = 1.0, ?Offset : vector3 = vector3{}) : void =
            # Applies scale and offset on `Triangles` and `Vertices`.
            NewTriangles := for (Triangle : Triangles):
                triangle:
                    A := Triangle.A
                    B := Triangle.B
                    C := Triangle.C
                    Translation := (Triangle.Translation * Scale) + Offset
            NewVertices := for (Vertex : Vertices):
                (Vertex * Scale) + Offset
            
            # Updates values.
            set Triangles = NewTriangles
            set Vertices = NewVertices
        
        Draw<public>(?VertexRadius : float = 16.0) : void =
            DebugDraw : debug_draw = debug_draw{Channel := dd_channel}
            # Offset vector for each vertex center.
            Offset := vector3{Z := VertexRadius}
            # Index of vertex -> Indexes of connected vertices.
            var DrawnVerticesFrom : [int][]int = map{}

            # Draw each triangle.
            for (I -> Triangle : Triangles):
                # List of `Triangle` edges.
                Edges : []edge = array:
                    edge{Left := Triangle.A; Right := Triangle.B}
                    edge{Left := Triangle.B; Right := Triangle.C}
                    edge{Left := Triangle.C; Right := Triangle.A}
                
                # Try to draw each `Edge`, and its vertices A and B.
                for (J -> Edge : Edges; A := Vertices[Edge.Left]; B := Vertices[Edge.Right]):
                    if (DrawnVertices := DrawnVerticesFrom[Edge.Left]):
                        # Draw edge if not already, add connection A->B, and try to draw vertex B.
                        if (not DrawnVertices.Find[Edge.Right]; set DrawnVerticesFrom[Edge.Left] += array{Edge.Right}):
                            DebugDraw.DrawLine(A + Offset, B + Offset, ?DrawDurationPolicy := debug_draw_duration_policy.Persistent)
                            # Add B->A connection.
                            if (set DrawnVerticesFrom[Edge.Right] += array{Edge.Left}) {}
                            # Draw vertex B sphere if not already.
                            else if (set DrawnVerticesFrom[Edge.Right] = array{Edge.Left}):
                                DebugDraw.DrawSphere(B + Offset, ?Radius := VertexRadius, ?NumSegments := 8,?DrawDurationPolicy := debug_draw_duration_policy.Persistent)
                    # Draw vertex A, edge, add connection A->B, and try to draw vertex B.
                    else if (set DrawnVerticesFrom[Edge.Left] = array{Edge.Right}):
                        # Draw vertex A sphere.
                        DebugDraw.DrawSphere(A + Offset, ?Radius := VertexRadius, ?NumSegments := 8,?DrawDurationPolicy := debug_draw_duration_policy.Persistent)
                        # Draw edge.
                        DebugDraw.DrawLine(A + Offset, B + Offset, ?DrawDurationPolicy := debug_draw_duration_policy.Persistent)
                        # Add B->A connection.
                        if (set DrawnVerticesFrom[Edge.Right] += array{Edge.Left}) {}
                        # Draw vertex B sphere if not already.
                        else if (set DrawnVerticesFrom[Edge.Right] = array{Edge.Left}):
                            DebugDraw.DrawSphere(B + Offset, ?Radius := VertexRadius, ?NumSegments := 8,?DrawDurationPolicy := debug_draw_duration_policy.Persistent)
