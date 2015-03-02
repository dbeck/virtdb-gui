TABLELIST = React.createClass(
    displayName: 'TABLELIST'
    render: ->
        getClass = (current, selected)  ->
            if (current == selected)
                return {className: 'info' }
            else
                return null

        checkHandler = (table) =>
            return (ev) =>
                @props.check(table)

        clickHandler = (tableName) =>
            return (ev) =>
                @props.click tableName

        children = []
        if this.props.data?
            for table in this.props.data
                row = []
                row.push React.DOM.td null, React.DOM.input { onChange: checkHandler(table), checked: table.selected, type: 'checkbox'}, null
                row.push React.DOM.td { onClick: clickHandler(table.name) }, table.name
                children.push React.DOM.tr getClass(table.name, this.props.selectedTable), row
        return React.DOM.table {className: 'table'}, React.DOM.tbody null, children 
    )

tableListDirective = ->
    restrict: 'E'
    scope:
        data: "="
        table: "="
        check: "="
        click: "="
        selectionCounter: "="
        configuredCounter: "="
    link: (scope, el, attrs) ->
        display = (data, table, check, click) =>
            if data?
                React.render TABLELIST(data: data, selectedTable: table, check: check, click: click), el[0]
        scope.$watch 'data', (newValue, oldValue) ->
            display newValue, scope.table, scope.check, scope.click
        scope.$watch 'table', (newValue, oldValue) ->
            display scope.data, newValue, scope.check, scope.click
        scope.$watch 'selectionCounter', (newValue, oldValue) ->
            display scope.data, scope.table, scope.check, scope.click
        scope.$watch 'configuredCounter', (newValue, oldValue) ->
            display scope.data, scope.table, scope.check, scope.click
