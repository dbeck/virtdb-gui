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

        changeMaterialization = (table) =>
            return (ev) =>
                @props.materialize table

        clickHandler = (table) =>
            return (ev) =>
                @props.click table

        children = []

        children.push R.td
            key: "materialization-wrap" + @props.table.name
            className: "materialization-" + @props.table.name
        , R.input
            key: "materialize-input" + @props.table.name
            onChange: changeMaterialization @props.table
            checked: @props.table.materialized
            disabled: not @props.table.selected
            type: 'checkbox'

        # onoff
        children.push R.td
            key: "onoff" + @props.table.name
            className: "switch-with-icon-cell"
        , R.table
            key: "inner" + @props.table.name
        , R.tr {},
        [
            R.td {className: "switch-cell"}, R.span {className: "switch"},
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
        ,
            # loading indicator
            R.td {}, R.i
                className: "transparent fa fa-check"
                id: "tableIcon" + @props.table.name
        ]

        children.push R.td
            name: @props.table.name
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
                    materialize: @props.materialize
                    selected: table.name is @props.selectedTable
        return React.DOM.table {className: 'table'}, React.DOM.tbody null, children
)

tableListDirective = ->
    restrict: 'E'
    scope:
        data: "="
        table: "="
        check: "="
        materialize: "="
        click: "="
        configuredCounter: "="
        materializedCounter: "="
    link: (scope, el, attrs) ->
        display = (data, table, check, materialize, click) ->
            if data?
                React.render(
                    React.createElement TableList,
                        data: data
                        selectedTable: table
                        check: check
                        materialize: materialize
                        click: click
                , el[0])
        scope.$watch 'data', (newValue, oldValue) ->
            display newValue, scope.table, scope.check, scope.materialize, scope.click
        scope.$watch 'table', (newValue, oldValue) ->
            display scope.data, newValue, scope.check, scope.materialize, scope.click
        scope.$watch 'configuredCounter', (newValue, oldValue) ->
            display scope.data, scope.table, scope.check, scope.materialize, scope.click
        scope.$watch 'materializedCounter', (newValue, oldValue) ->
            display scope.data, scope.table, scope.check, scope.materialize, scope.click

module.exports = tableListDirective
