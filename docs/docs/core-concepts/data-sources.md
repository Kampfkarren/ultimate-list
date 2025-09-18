---
sidebar_position: 2
---
# Data Sources
A data source represents what data will be rendered in the list. For example, the data for a chat room would be the messages sent, as well as metadata such as who sent them.

## Arrays
The easiest data source to provide is a simple array. This can be done through `UltimateList.DataSources.array`. This array must be immutable like React state usually is--you must provide a different array to the UltimateList in order to update it.

In the introduction example, we saw this:

```lua
local letters = {}
for offset = 0, 25 do
    table.insert(letters, string.char(string.byte("A") + offset))
end

return React.createElement(UltimateList.Components.ScrollingFrame, {
    dataSource = UltimateList.DataSources.array(letters),

    -- Rest omitted...
})
```

If we wanted something more dynamic, it might look something like this:
```lua
local letters: { string }, setLetters = React.useState({} :: { string })

React.useEffect(function()
    local thread = task.spawn(function()
        for offset = 0, 25 do
            -- Update the `letters` state, but never mutating the array.
            setLetters(function(newLetters)
                newLetters = table.clone(newLetters)
                table.insert(newLetters, string.char(string.byte("A") + offset))
                return newLetters
            end)

            task.wait(0.5)
        end
    end)

    return function()
        task.cancel(thread)
    end
end, {})

return React.createElement(UltimateList.Components.ScrollingFrame, {
    dataSource = UltimateList.DataSources.array(letters),

    -- Rest omitted...
})
```

## Mutable sources

:::info
Mutable sources are an advanced feature. You can probably just use [arrays](#arrays).
:::

Sometimes the cost of updating an array can be too expensive, or will incur a React re-render that you wouldn't otherwise want. In the case where this poses a performance issue, you can opt instead for a **mutable source**.

A mutable source assumes nothing about the underlying data, and instead calls to methods you provide for getting it and alerting it to changes. This is done through `UltimateList.DataSources.mutableSource(mutableSourceMethods)`.

`mutableSourceMethods` is a table with the following fields:

### Required fields

#### `get: (startIndex: number) -> DataSourceCursor<T>?`

Given an index, provides a cursor that points to that value, if it exists, as well as provides a way to go forwards and backwards. The results provided by `get` **must** be sorted in ascending order.

`DataSourceCursor<T>` is defined as follows:
```ts
type DataSourceCursor<T> = {
    before: () -> DataSourceCursor<T>?,
    value: T,
    after: () -> DataSourceCursor<T>?,
}
```

If you only have a function for going from index to value, then you can use `DataSources.utilities.createGetSimpleCursor` to produce this for you. 

```ts
DataSources.utilities.createGetSimpleCursor<T>(
    get: (index: number) -> T,
    getLength: () -> number,
)
```

This can be used like so:

```lua
UltimateList.DataSources.mutableSource({
    get = DataSources.utilities.createGetSimpleCursor(
        -- Getter
        function(index: number): T
            -- Note that we return `T` and not `T?`.
            -- UltimateList will never provide an index not in the range of 1 <= index <= length,
            -- and thus every element being requested is expected to exist.
            return myData[index]
        end,

        -- Get length
        function(): number
            return #number
        end
    ),

    -- Other required fields...
})
```

<details>
    <summary>Why does `get` return a cursor instead of just the item?</summary>

    Some data structures have a different time complexity for going forwards/backwards than for indexing. For example, a binary search tree provides `O(log n)` access, meaning getting m elements naively is `O(m log n)`. However, going from an existing element to the element before or afterwards is `O(1)`: getting the previous element is going to the left in the tree, and getting the next element is going to the right.
    
    These kinds of tree-like structures are expected for specific use cases, such as the data model instance tree where elements can be removed or inserted anywhere in the collection.
</details>

#### `length: () -> number`
This returns the length of the data source.

#### `bindToChanged: (callback: () -> ()) -> () -> ()`
This function takes a callback that will be called when the data updates, and returns a function to disconnect that callback when it is no longer necessary.

<details>
    <summary>That's a lot of parentheses, how do I read that type signature?</summary>

    Let's work our way to it by starting with a function that takes nothing, and returns nothing.

    `bindToChanged: () -> ()`

    Now we want to return the destructor. In other words, a function that returns a function.

    `bindToChanged: () -> () -> ()`

    Now, let's make it take a callback, another function that takes nothing and returns nothing.

    `bindToChanged: (callback: () -> ()) -> () -> ()`

    If it helps, you can also imagine this with type aliases:

    ```ts
    type Callback = () -> ()

    // ...
    bindToChanged: (Callback) -> Callback
    ```
</details>

### Optional fields

Some data structures offer extra opportunities for optimization in special use cases, but these provide reasonable defaults when that's not the case.

#### `back: () -> T?`
This returns the last element in the data source. It defaults to the result of `get(length())`.

An example of a data source that might implement this is a binary search tree, where getting the last element can be done efficiently by repeatedly going through the rightmost node.

#### `getByRange: (startIndex: number, endIndex: number) -> { T }`
This returns elements from startIndex to (and including) endIndex. It defaults to `get(startIndex)`, and then repeatedly calling `.after()`.

A data source built over a simple array might use this to specialize for using `table.move`, which is more efficient than getting each element individually.
