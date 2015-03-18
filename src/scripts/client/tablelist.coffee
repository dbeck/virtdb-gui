R = React.DOM

TableItem = React.createClass(
    displayName: "TableItem"
    render: ->
        getClass = =>
            ret =
                onClick: @props.onClick
            if @props.selected then ret.className = 'info'
            return ret

        checkHandler = (table) =>
            return (ev) =>
                @props.check table

        clickHandler = (table) =>
            return (ev) =>
                @props.click table

        refreshButton = (table) ->
            if not table.selected or not table.outdated
                return null
            R.span
                className: 'glyphicon glyphicon-refresh'
            , null

        children = []

        # Refresh
        children.push R.td
            key: "refresh" + @props.table.name
        , refreshButton @props.table

        # onoff
        children.push R.td
            key: "onoff" + @props.table.name
        , R.div {className: "switch"},
            [
                R.input
                    key: "input-onoff" + @props.table.name
                    onChange: checkHandler(@props.table)
                    checked: @props.table.selected
                    type: 'checkbox'
                    name: 'switch'
                    className: 'cmn-toggle cmn-toggle-round-flat'
                    id: 'switch' + @props.table.name
                , null
            ,
                R.label
                    key: "label-onoff" + @props.table.name
                    htmlFor: 'switch' + @props.table.name
            ]

        children.push R.td
            key: "tableName" + @props.table.name
            onClick: clickHandler(@props.table)
        , @props.table.name
        
        return R.tr getClass(), children
)

TableList = React.createClass(
    displayName: 'TableList'
    render: ->
        children = []
        if this.props.data?
            for table,index in this.props.data
                children.push React.createElement TableItem,
                    key: index
                    table: table
                    click: @props.click
                    check: @props.check
                    selected: table.name == @props.selectedTable
        return React.DOM.table {className: 'table'}, React.DOM.tbody null, children
)

tableListDirective = ->
    restrict: 'E'
    scope:
        data: "="
        table: "="
        check: "="
        click: "="
        configuredCounter: "="
    link: (scope, el, attrs) ->
        display = (data, table, check, click) ->
            if data?
                React.render(
                    React.createElement TableList,
                        data: data
                        selectedTable: table
                        check: check
                        click: click
                , el[0])
        scope.$watch 'data', (newValue, oldValue) ->
            display newValue, scope.table, scope.check, scope.click
        scope.$watch 'table', (newValue, oldValue) ->
            display scope.data, newValue, scope.check, scope.click
        scope.$watch 'configuredCounter', (newValue, oldValue) ->
            display scope.data, scope.table, scope.check, scope.click
