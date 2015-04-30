R = React.DOM
VirtDB = React.createClass(
    displayName: 'VirtDB'
    render: ->
        clickHandler = (fieldName) =>
            return (ev) =>
                @props.callback fieldName

        style = (field) =>
            if @props.selectedField == field
                "info"
            else
                ""

        rows = []
        if @props.data?
            transposedData = []
            for row, rowIndex in @props.data
                children = []
                for field, index in row
                    item = R.td
                        key: index + "-" + rowIndex
                        onClick: clickHandler(@props.header[index])
                        className: style(@props.header[index])
                    , field
                    if @props.transposed
                        transposedData[index] ?= [ R.th
                                key: 'header' + index + '-' + rowIndex
                                onClick: clickHandler(@props.header[index])
                                className: style(@props.header[index])
                            , @props.header[index]
                        ]
                        transposedData[index].push item
                    else
                        children.push item
                if not @props.transposed
                    rows.push R.tr
                        key: 'row' + rowIndex
                    , children
            if @props.transposed
                for row, rowIndex in transposedData
                    rows.push R.tr
                        key: 'transposed' + rowIndex
                    , row

        headItems = []
        if @props.header?
            for field in @props.header
                headItems.push R.th
                    key: field
                    onClick: clickHandler(field)
                    className: style(field)
                , field
        tableParts = []
        if not @props.transposed
            headerRow = R.tr null, headItems
            tableParts.push R.thead
                key: "thead"
            , headerRow
        tableParts.push R.tbody
            key: 'tbody'
        , rows
        return R.table {className: "table table-bordered"}, tableParts
)

virtdbTableDirective = ->
    restrict: 'E'
    scope:
        data: '='
        header: '='
        callback: '='
        selectedField: '='
        transposed: '='
    link: (scope, el, attrs) ->
        display = (data, header, callback, selectedField, transposed) ->
            React.render(
                React.createElement VirtDB,
                    data: data
                    header: header
                    callback: callback
                    selectedField: selectedField
                    transposed: transposed
            , el[0])
        scope.$watch 'data', (newValue, oldValue) ->
            display newValue, scope.header, scope.callback, scope.selectedField, scope.transposed
        scope.$watch 'selectedField', (newValue, oldValue) ->
            display scope.data, scope.header, scope.callback, newValue, scope.transposed
        scope.$watch 'transposed', (newValue, oldValue) ->
            display scope.data, scope.header, scope.callback, scope.selectedField, newValue
        return

module.exports = virtdbTableDirective
