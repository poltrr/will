
MinHeapByPoltrr<public> := module:
    # Types #
    
    # A pair of indexes.
    indexes<internal> := tuple(int, int)

    # Interfaces #
    
    # Interface for fully comparable type.
    # Update when overloading for all comparison operators is implemented.
    # Remove when min_heap is implemented.
    comparable_type<public> := interface:
        IsLessThan<public>(Compare : comparable_type)<transacts><decides> : void
        IsGreaterThan<public>(Compare : comparable_type)<transacts><decides> : void

    # Classes #
    
    # Minheap parametric implementation.
    # Complete when mutable members in parametric classes are implemented.
    min_heap<public>(t : type) := class<concrete> {}
    
    # Minheap implementation for `comparable_type`.
    # Remove when min_heap is implemented.
    min_heap_comparable_type<public> := class<final><concrete>:
        # Attributes #
        
        # Array representation of a heap tree.
        var HeapArray<private> : []comparable_type = array{}

        # Methods #

        # Return the minimum value of the heap.
        Top<public>()<transacts><decides> : comparable_type =
            HeapArray[0]
        
        # Remove the minimum value from the heap.
        Pop<public>()<transacts><decides> : void =
            LastIndex : int = HeapArray.Length - 1
            Swap[0, LastIndex]
            set HeapArray = HeapArray.RemoveElement[LastIndex]
            if (not Empty[]):
                SiftDown[0]
        
        # Insert a new value into the heap.
        Push<public>(Value : comparable_type)<transacts><decides> : void =
            set HeapArray += array{Value}
            SiftUp[HeapArray.Length - 1]
        
        # Return the amount of elements in the heap.
        Size<public>()<transacts> : int = 
            HeapArray.Length
        
        # Succeeds if there are no elements in the heap.
        Empty<public>()<transacts><decides> : void =
            Size() = 0
        
        # Move element in `Index` up to its correct position.
        # This is an old implementation. Deprecate soon.
        SiftUp<private>(Index : int)<transacts><decides> : void =
            var CurrentIndex : int = Index
            var CurrentValue : comparable_type = HeapArray[CurrentIndex]
            var ParentIndex : int = GetParentIndex[CurrentIndex]
            
            var ShouldRollback : logic = false
            loop:
                if:
                    var ParentValue : comparable_type = HeapArray[ParentIndex]
                    CurrentValue.IsLessThan[ParentValue]
                then:
                    if:
                        Swap[CurrentIndex, ParentIndex]
                        set CurrentIndex = ParentIndex
                        set ParentIndex = GetParentIndex[CurrentIndex]
                    else:
                        set ShouldRollback = true
                        break
                else:
                    break
            not ShouldRollback?
        
        # Move element in `Index` down to its correct position.
        # This is an old implementation. Deprecate soon.
        SiftDown<private>(Index : int)<transacts><decides> : void =
            # Indexes
            var CurrentIndex : int = Index
            ChildrenIndexes : indexes = GetChildrenIndexes[CurrentIndex]
            var LeftIndex : int = ChildrenIndexes(0)
            var RightIndex : int = ChildrenIndexes(1)
            # Values
            var CurrentValue : comparable_type = HeapArray[CurrentIndex]
            
            HeapLength : int = HeapArray.Length
            var ShouldRollback : logic = false
            loop:
                if:
                    LeftIndex < HeapLength and
                    CurrentValue.IsGreaterThan[HeapArray[LeftIndex]] or
                    RightIndex < HeapLength and
                    CurrentValue.IsGreaterThan[HeapArray[RightIndex]]
                then:
                    if:
                        Smallest : int = 
                            if:
                                RightIndex >= HeapLength or 
                                HeapArray[LeftIndex].IsLessThan[HeapArray[RightIndex]]
                            then: 
                                LeftIndex 
                            else: 
                                RightIndex
                        Swap[CurrentIndex, Smallest]
                        set CurrentIndex = Smallest
                        NewChildrenIndexes : indexes = GetChildrenIndexes[CurrentIndex]
                        set LeftIndex = NewChildrenIndexes(0)
                        set RightIndex = NewChildrenIndexes(1)
                    else:
                        set ShouldRollback = true
                        break
                else:
                    break
            not ShouldRollback?
        
        # Return the parent's index of the element in `Index`.
        GetParentIndex<private>(Index : int)<transacts><decides> : int =
            Floor((Index - 1) / 2)
        
        # Return children indexes of element in `Index`.
        GetChildrenIndexes<private>(Index : int)<transacts><decides> : indexes =
            LeftIndex : int = 2 * Index + 1
            (LeftIndex, LeftIndex + 1)
        
        # Swap values in the heap.
        Swap<private>(LIndex : int, RIndex : int)<transacts><decides> : void =
            LValue : comparable_type = HeapArray[LIndex]
            set HeapArray[LIndex] = HeapArray[RIndex]
            set HeapArray[RIndex] = LValue
