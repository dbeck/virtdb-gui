VIRTDB = React.createClass(
    displayName: 'VIRTDB'
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
            for row in @props.data
                children = []
                for field, index in row
                    item = React.DOM.td { onClick: clickHandler(@props.header[index]), className: style(@props.header[index])}, field
                    if @props.transposed
                        transposedData[index] ?= [ React.DOM.th {onClick: clickHandler(@props.header[index]), className: style(@props.header[index])}, @props.header[index] ]
                        transposedData[index].push item
                    else
                        children.push item
                if not @props.transposed
                    rows.push React.DOM.tr(null, children)
            if @props.transposed
                for row in transposedData
                    rows.push React.DOM.tr(null, row)

        headItems = []
        if @props.header?
            for field in @props.header
                headItems.push React.DOM.th { onClick: clickHandler(field), className: style(field)}, field
        tableParts = []
        if not @props.transposed
            headerRow = React.DOM.tr null, headItems
            tableParts.push React.DOM.thead null, headerRow
        tableParts.push React.DOM.tbody null, rows
        return React.DOM.table {className: "table table-bordered"}, tableParts
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
        display = (data, header, callback, selectedField, transposed) =>
            React.render VIRTDB(data: data, header: header, callback: callback, selectedField: selectedField, transposed: transposed), el[0]
        scope.$watch 'data', (newValue, oldValue) ->
            display newValue, scope.header, scope.callback, scope.selectedField, scope.transposed
        scope.$watch 'selectedField', (newValue, oldValue) ->
            display scope.data, scope.header, scope.callback, newValue, scope.transposed
        scope.$watch 'transposed', (newValue, oldValue) ->
            display scope.data, scope.header, scope.callback, scope.selectedField, newValue
        return

